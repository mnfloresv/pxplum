# Pxplum
Tool to boot computers via PXE to inventory, diagnosis, benchmark and cloning images through a web interface.

## Descripción
Pxplum consiste en una herramienta basada en una distribución ligera de GNU/Linux a distribuir como live-cd con opción a ser instalada, que permite arrancar los equipos de una red a través de PXE y controlarlos mediante una interfaz web.

El proyecto pretende unir diferentes herramientas de administración de sistemas para agilizar el trabajo de instalación del sistema operativo sobre un conjunto de ordenadores en un aula, taller de informática o para reciclar equipos usados.

Las funciones que se podrán realizar sobre dichos equipos serán: realizar un inventario de los componentes de hardware, un chequeo o diagnóstico de memoria y disco, un benchmark para analizar el rendimiento, o clonar todos los equipos con una imagen de un sistema ya instalado.

## Motivación
Pxplum surge como idea durante el proyecto Software Libre para el Sahara, para automatizar todo el proceso técnico de preparación de los equipos informáticos.

## Estructura

* `pxplum-server`: Ficheros y configuración del servidor, basado en SliTaz GNU/Linux.

* `pxplum-client`: Ficheros de la imagen del cliente PXE, basado en SliTaz GNU/Linux.

* `pxplum-web`: Panel de administración web realizado con el framework Sinatra.

* `pxplum-builder.sh`: Script para construir las imágenes ISO.

* `slitaz-pxplum-server.iso`: Imagen ISO generada.

## Pxplum builder

```
Pxplum builder 0.5

This script builds the server image of Pxplum with the
client image for PXE, and the web interface included.

Usage:
./pxplum-builder.sh [--only-server] [--update-packages] [--update-gems] [--new-dropbear-keys]
./pxplum-builder.sh -h | --help
./pxplum-builder.sh -v | --version

Options:
--only-server           Build only the server if possible.
--update-packages       Upgrade the packages list to the latest versions.
--update-gems           Update the installed Ruby gems.
--new-dropbear-keys     Generate a new SSH key pair.
--help                  Show this help.
--version               Show the version.
```

## Uso del Live CD

La imagen ISO del servidor puede ser arrancada en un equipo físico o en una máquina virtual como VirtualBox configurando la interfaz de red en modo puente.

El resto de equipos podrán arrancar por red activando esta opción en la BIOS, o bien utilizando el cargador Etherboot/gPXE desde un disquete o pendrive USB.

## Panel de administración web

Captura de pantalla:

![Dashboard](http://i.imgur.com/gWtdpYS.png "Dashboard")
