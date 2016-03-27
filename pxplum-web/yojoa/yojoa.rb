class Job
  def initialize(command)
    @command=command
    @status="stopped"
    @output=""
    @result=nil
    run
  end
  
  attr_reader :command, :status, :output, :result
  
  private
  
  def run
    @status="running"
    t = Thread.new do #thread, popen (see fibers)
      IO.popen("#{command}") do |stdout|
    	  bs=0
        stdout.each_byte do |b| #each_byte
          if b.chr == "\b"
            bs+=1
          else
            @output=@output[0..-1-bs] + b.chr
            bs=0
          end
        end
      end
      
      @result=$?
      @status="finished"
    end
  end
end

class Yojoa
  def initialize #inicializa
    @joblist={} #hash
  end
  
  def addjob(id, command) #añade una tarea
    if !@joblist.has_key?(id)  
      @joblist[id] = Job.new(command)
    else
      raise "id in use"
    end
  end
  
  def numjobs #numero de tareas
    return @joblist.size
  end
  
  def joblist #lista de ids de tareas
    return @joblist.keys
  end
  
  def job(id) #devuelve la tarea n como hash
    j=@joblist[id]
    return {:command=>j.command, :status=>j.status, :output=>j.output, :result=>j.result}
  end
  
  def deletejob(id)
    @joblist.delete(id)
  end
    
end
