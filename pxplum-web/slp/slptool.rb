# Scans continuously for pxplum services
class SLPTool

  def initialize
    @computers={}
    # Make the search in a separate thread
    @thread=Thread.new { findattrs }
  end

  # Aborts the thread and starts a new search immediately
  def refresh
    @thread.kill
    @thread=Thread.new { findattrs }
  end

  attr_reader :computers

  private

  # Searches for pxplum services in infinite loop
  def findattrs
    while 1 do
      output=`slptool findattrs service:pxplum`
      @computers=convert_output_to_hash(output)

      sleep 30
    end
  end

  # Returns a hash as result to process the output
  def convert_output_to_hash(output)
    hash1=Hash.new
    output.split("\n").each do |line|
      hash2=Hash.new
      line.split(',').each do |asig|
        pair=asig.scan(/\((.+)=(.+)\)/)[0]
        if pair then
          hash2[pair[0]] = pair[1]
        end
      end

      hwaddr=hash2["hwaddr"]
      if hwaddr then
        hash1[hwaddr] = hash2
      end
    end
    return hash1
  end

end
