require 'sinatra/base'
require 'haml'
require_relative 'slp/slptool.rb'
require_relative 'yojoa/yojoa.rb'
require_relative 'mac-vendor/mac-vendor.rb'

class Pxplum < Sinatra::Base
  @slp=SLPTool.new
  @jobman=Yojoa.new
  @computer_actions=Hash.new

  def self.rrun(ip, command)
    #`dbclient -y -i /root/.ssh/id_rsa #{ip} "#{command}" < /dev/zero`
    `dbclient -y -i id_rsa root@#{ip} "#{command}" < /dev/zero`
  end

  def self.rrun_command(ip, command)
    "dbclient -y -i /root/.ssh/id_rsa #{ip} \"#{command}\" < /dev/zero"
  end

  class << self
    attr_accessor :computer_actions
    attr_reader :slp, :jobman
  end

  configure do
    set :root, File.dirname(__FILE__)
  end

  get '/' do
    @computers = Pxplum.slp.computers
    haml :dashboard1
  end

  post '/computers' do
    @computers = Pxplum.slp.computers
    haml :computers, :layout => false
  end

  get '/computer/:hwaddr' do |hwaddr|
    #if Pxplum.slp.computers[hwaddr] then
      @hwaddr=hwaddr
      #@ip=Pxplum.slp.computers[hwaddr]['ip']
      @sysinfo=Pxplum.rrun(@ip, 'uname -a')
      @uptime=Pxplum.rrun(@ip, 'uptime')
      @computer_actions=Pxplum.computer_actions
      haml :computer
    #else
    #  haml "%h3 Computer not accessible :("
    #end
  end

  get '/computer/:hwaddr/:action' do |hwaddr, action|
    if Pxplum.slp.computers[hwaddr] then
      if Pxplum.computer_actions[action] then
        if Pxplum.computer_actions[action][:haml] then
          @hwaddr=hwaddr
          haml :"#{Pxplum.computer_actions[action][:haml]}"
        end
      else
        haml "Wrong action :("
      end
    else
      haml "Computer not accessible :("
    end
  end

  post '/computer/:hwaddr/:action' do |hwaddr, action|
    if Pxplum.slp.computers[hwaddr] then
      if Pxplum.computer_actions[action] then
        if Pxplum.computer_actions[action][:command] then
          Pxplum.rrun(Pxplum.slp.computers[hwaddr]['ip'], Pxplum.computer_actions[action][:command])
          if $?.success? then
            "OK :)"
          else
            "Error"
          end
        end
      else
        "Wrong action :("
      end
    else
     "Computer not accessible :("
    end
  end


end

#load "./actions.rb"
