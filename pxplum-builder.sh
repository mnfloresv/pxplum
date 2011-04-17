#!/bin/sh
# pxplum-builder.sh - Script for building Pxplum distro
#
# This script builds the server image of Pxplum with the
# client image for PXE, and the web interface included.
#
VERSION="0.5"
#
# Author: Manuel Flores <manuelfloresv [at] gmail [dot] com>
#
# Creation date: 15/Apr/2011
#
# Usage:
# ./pxplum-builder.sh [--only-server] [--update-packages] [--update-gems] [--new-dropbear-keys]
# ./pxplum-builder.sh -h | --help
# ./pxplum-builder.sh -v | --version
#

# Constants
PXPLUM_PATH=$(pwd)
SERVER_FLAVOR="pxplum-server"
CLIENT_FLAVOR="pxplum-client"
PXELINUX_LZMA="/usr/share/boot/pxelinux.0.lzma"

# Load configuration file
#CONFIG_FILE="pxplum.conf"
#if [ -e $CONFIG_FILE ]; then
#    . $PXPLUM_PATH/$CONFIG_FILE
#else
#    echo "Configuration file: $CONFIG_FILE not found."
#    exit 1
#fi

# Inizialitation of variables for parameters
only_server="no"
update_packages="no"
update_gems="no"
new_dropbear_keys="no"

# Print functions
print_line() {
    echo "================================================================================"
}

print_step() {
    echo -e "\033[1m$1\033[0m"
    print_line
}

print_ok() {
    echo -e "$1\\033[70G[ \\033[1;32mOK\\033[0;39m ]"
}

print_fail() {
    echo -e "\\033[70G[ \\033[1;31mFailed\\033[0;39m ]"
    print_endline "$1"
}

print_endline() {
    print_line
    echo "$1"
    echo
}

# Displays the help
help() {
    echo "Pxplum builder $VERSION"
    echo
    echo "This script builds the server image of Pxplum with the"
    echo "client image for PXE, and the web interface included."
    echo
    echo "Usage:"
    echo "$0 [--only-server] [--update-packages] [--update-gems] [--new-dropbear-keys]"
    echo "$0 -h | --help"
    echo "$0 -v | --version"
    echo
    echo "Options:"
    echo -e "--only-server\t\tBuild only the server if possible."
    echo -e "--update-packages\tUpgrade the packages list to the latest versions."
    echo -e "--update-gems\t\tUpdate the installed Ruby gems."
    echo -e "--new-dropbear-keys\tGenerate a new SSH key pair."
    echo -e "--help\t\t\tShow this help."
    echo -e "--version\t\tShow the version."
    echo
}

# Outputs the elements in $2, but not in $1 (relative complement)
list_diff() {
    for e2 in $2; do
        found=0
        for e1 in $1; do
            if [ "$e1" == "$e2" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "$e2"
        fi
    done
}

# Checks the dependencies needed to build
check_deps() {
    print_step "Checking dependencies"

    # Check if root
    echo -n "Checking if user is root..."
    if [ $(id -u) != 0 ]; then
        print_fail "You must run as root."
        exit 1
    fi
    print_ok

    # Check if project directories exists
    echo "Checking if project directories exists..."
    DIRS_NEEDED="$CLIENT_FLAVOR $SERVER_FLAVOR pxplum-web"
    for dir in $DIRS_NEEDED; do
        echo -n "* Checking $dir dir..."
        if [ ! -d "$dir" ]; then
            print_fail "$dir directory not exists in $PXPLUM_PATH."
            exit 1
        fi
        print_ok
    done

    # Check more directories
    DIRS_TO_CREATE="$SERVER_FLAVOR/rootfs/usr $SERVER_FLAVOR/rootfs/tftp/slitaz-$CLIENT_FLAVOR \
                    $SERVER_FLAVOR/rootfs/root/.ssh $CLIENT_FLAVOR/rootfs/root/.ssh"
    for dir in $DIRS_TO_CREATE; do
        echo -n "* Checking $dir dir..."
        if [ ! -d "$dir" ]; then
            echo
            echo -n "* Creating $dir...";
            mkdir -p $dir
        fi
        print_ok
    done

    # Check if needed commands exists
    echo "Checking if needed commands are installed..."
    COMMANDS="tazlito unlzma find rsync dropbearkey gem"
    for c in $COMMANDS; do
        echo -n "* Checking $c..."
        if ! hash "$c" > /dev/null 2>&1; then
            print_fail "$c not found, install it."
            exit 1
        fi
        print_ok
    done

    # Check if pxelinux file exists
    echo -n "Checking if pxelinux file exists..."
    if [ ! -e $PXELINUX_LZMA ]; then
        print_fail "$PXELINUX_LZMA not found, install syslinux-extra."
        exit 1
    fi
    print_ok

    # Check backup files
    echo -n "Checking *~ files..."
    bfiles=$(find pxplum-*/ -name "*~")
    if [ -n "$bfiles" ]; then
        echo
        echo "Found:"
        echo "$bfiles"
        echo -n "Delete them to continue? [Y/n] "
        read delbfiles
        echo -n "Deleting *~ files..."
        case $delbfiles in
            y|yes|Y|YES|"")
                if rm $bfiles; then
                    print_ok
                else
                    print_fail "Error when deleting the files."
                    exit 1
                fi
                ;;
            *)
                print_fail "You must delete the *~ files to continue."
                exit 1
                ;;
        esac
    fi

    # Check tazlito.conf
    echo -n "Checking tazlito.conf..."
    if [ ! -e tazlito.conf ]; then
        echo
        tazlito gen-config
        sed -i "s/^PACKAGES_REPOSITORY=\"\"/PACKAGES_REPOSITORY=\"\$(pwd)\/packages\"/
s/^DISTRO=\"\"/DISTRO=\"\$(pwd)\/distro\"\n\n\
# Path to the LiveCD flavors files\n\
FLAVORS_REPOSITORY=\"\$(pwd)\"/" tazlito.conf
    else
        print_ok
    fi

    print_endline "All requirements are OK"
}

# Manages RubyGems needed
manage_gems() {
    echo "Starting RubyGems management process..."
    gems_dir="$SERVER_FLAVOR/rootfs$(gem environment gemdir)"
    bin_dir="$SERVER_FLAVOR/rootfs/usr/bin"
    
    gems=$( [ -e pxplum-web/gemdeps ] && cat pxplum-web/gemdeps | sort | uniq )
    installed_gems=$( [ -e $gems_dir/installed-gems.list ] && cat $gems_dir/installed-gems.list )

    gems_to_install=$(list_diff "$installed_gems" "$gems")
    gems_to_uninstall=$(list_diff "$gems" "$installed_gems")

    # Install new gems
    if [ -n "$gems_to_install" ]; then
        echo -e "Gems to install:"
        echo $gems_to_install
        for g in $gems_to_install; do
            echo "Installing $g..."
            if GEM_HOME="$gems_dir" GEM_PATH="$gems_dir" gem install $g -i $gems_dir -n $bin_dir --no-rdoc --no-ri; then
                echo $g >> $gems_dir/installed-gems.list
            else
                print_endline "Error installing new gems: $g could not be installed."
                exit 1
            fi
        done
    fi

    # Uninstall old gems
    if [ -n "$gems_to_uninstall" ]; then
        echo -e "Gems to uninstall:"
        echo $gems_to_uninstall
        for g in $gems_to_uninstall; do
            echo "Uninstalling $g..."
            if GEM_HOME="$gems_dir" GEM_PATH="$gems_dir" gem uninstall $g -i $gems_dir -n $bin_dir; then
                sed -i "/^$g$/ d" $gems_dir/installed-gems.list
            else
                print_endline "Error uninstalling old gems: $g could not be uninstalled."
                exit 1
            fi
        done
    fi

    # Update installed gems
    if [ "$update_gems" == "yes" ]; then
        if ! GEM_HOME="$gems_dir" GEM_PATH="$gems_dir" gem update -i $gems_dir -n $bin_dir --no-rdoc --no-ri; then
            print_endline "Error updating installed gems."
            exit 1
        fi
        if ! GEM_HOME="$gems_dir" GEM_PATH="$gems_dir" gem cleanup; then
            print_endline "Error cleaning up old versions of installed gems."
            exit 1
        fi
    fi

    echo -n "RubyGems management process finished..."
    print_ok
}

# Generates a distro with tazlito
tazlito_gen_distro() {
    # Pack flavor directory
    if ! tazlito pack-flavor $1; then
        print_endline "Error to pack-flavor $1."
        exit 1
    fi

    # Upgrade package list
    if [ "$update_packages" == "yes" ]; then
        if ! tazlito upgrade-flavor $1; then
            print_endline "Error to upgrade-flavor $1."
            exit 1
        fi
    fi

    # Get flavor
    if ! tazlito get-flavor $1.flavor; then
        print_endline "Error to gen-flavor $1."
        exit 1
    fi

    # Gen distro
    tazlito clean-distro
    if ! tazlito gen-distro; then
        print_endline "Error to gen-distro $1."
        exit 1
    fi
}

# Build process
build() {
    #Check if dropbear keys exists
    dropbear_priv_key="$SERVER_FLAVOR/rootfs/root/.ssh/id_rsa"
    dropbear_pub_key="$CLIENT_FLAVOR/rootfs/root/.ssh/authorized_keys"

    if [[ ! -e $dropbear_priv_key || ! -e $dropbear_pub_key ]]; then
        new_dropbear_keys="yes"
    fi
    
    # Check if is needed to create client image
    if [ "$only_server" == "yes" ]; then
        if [[ ! -e $SERVER_FLAVOR/rootfs/tftp/slitaz-$CLIENT_FLAVOR/bzImage || \
              ! -e $SERVER_FLAVOR/rootfs/tftp/slitaz-$CLIENT_FLAVOR/rootfs.gz || \
              "$new_dropbear_keys" == "yes" ]]; then
            echo "Forcing client image creation."
            echo
            only_server="no"
        fi
    fi

    # Prepare client flavor
    if [[ "$only_server" == "no" && "$new_dropbear_keys" == "yes" ]]; then
        print_step "Preparing client flavor"
    
        #Generate a new SSH key pair
        if [ "$new_dropbear_keys" == "yes" ]; then
            #Delete old secret key
            if [ -e $dropbear_priv_key ]; then
                echo -n "Deleting old dropbear secret key..."
                rm $dropbear_priv_key
                print_ok
            fi

            if dropbearkey -t rsa -f $dropbear_priv_key &&
               dropbearkey -y -f $dropbear_priv_key | grep "^ssh-rsa" > $dropbear_pub_key; then
                echo -n "Generating a new SSH key pair..."
                print_ok
            else
                echo -n "Generating a new SSH key pair..."
                print_fail "Error when generating new dropbear keys."
                exit 1
            fi
        fi
        print_endline "Client flavor OK"
    fi

    # Prepare server flavor
    print_step "Preparing server flavor"

    # Unlzma pxelinux image if not exists or is newer
    PXELINUX="$SERVER_FLAVOR/rootfs/tftp/pxelinux.0"
    if [[ ! -e $PXELINUX || $PXELINUX_LZMA -nt $PXELINUX ]]; then
        echo -n "unlzma pxelinux image..."
        if ! unlzma d $PXELINUX_LZMA $PXELINUX; then
            print_fail "Error when unlzma pxelinux image."
            exit 1
        fi
        print_ok
    fi

    # Manage gems (install new gems, remove old gems, and update installed gems if was indicated)
    manage_gems

    # Copy pxplum-web in server flavor
    echo -n "Copying web directory to server flavor..."
    if [ ! -e $SERVER_FLAVOR/rootfs/home/pxplum ]; then
        mkdir -p $SERVER_FLAVOR/rootfs/home/pxplum
    fi

    if ! rsync --archive --delete --exclude '*~' pxplum-web $SERVER_FLAVOR/rootfs/home/pxplum; then
        print_fail "The web directory could not be copied to server flavor."
        exit 1
    fi
    print_ok

    print_endline "Server flavor OK"

    # Build client distro
    if [ "$only_server" == "no" ]; then
        print_step "Building the client"

        # Build the distro
        tazlito_gen_distro $CLIENT_FLAVOR

        # Copy to server flavor directory
        echo -n "Copying to server flavor..."
        if [[ ! -e distro/rootcd/boot/bzImage || ! -e distro/rootcd/boot/rootfs.gz ]]; then
            print_fail "bzImage and/or rootfs.gz not found in distro/rootcd/boot directory."
            exit 1
        fi
        cp distro/rootcd/boot/bzImage $SERVER_FLAVOR/rootfs/tftp/slitaz-$CLIENT_FLAVOR/bzImage
        cp distro/rootcd/boot/rootfs.gz $SERVER_FLAVOR/rootfs/tftp/slitaz-$CLIENT_FLAVOR/rootfs.gz
        print_ok

        print_endline "Client image OK"
    fi

    # Build server distro
    print_step "Building the server"
    tazlito_gen_distro $SERVER_FLAVOR
    print_endline "Server image OK"
}

# Read parameters
if [ $# -eq 1 ] ; then
    case "$1" in
        -h|--help)
            help
            exit 2
            ;;
        -v|--version)
            echo "Pxplum builder $VERSION"
            exit 2
            ;;
    esac
fi

while [ $# -ge 1 ]; do
    case "$1" in
        --only-server)
            only_server="yes"
            ;;
        --update-packages)
            update_packages="yes"
            ;;
        --update-gems)
            update_gems="yes"
            ;;
        --new-dropbear-keys)
            new_dropbear_keys="yes"
            ;;
        *)
            echo "Pxplum builder $VERSION"
            echo "Try: $0 --help"
            exit 1
            ;;
        esac
    shift
done

# Print introduction
echo "Pxplum builder $VERSION"
echo "Use --help to know more options."
echo
echo "Starting the process, this will take some time..."
echo

# Start build_process
start_time=$(date +%s)
check_deps
build

# Print total time
end_time=$(date +%s)
build_time=$(( $end_time - $start_time ))
build_mins=$(( $build_time / 60 ))
build_secs=$(( $build_time % 60 ))
echo "Total time: $build_mins mins and $build_secs secs."

exit 0

