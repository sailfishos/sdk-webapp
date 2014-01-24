require './shell_process'

class CCProcess
  class Failed < Exception; end
  @@process=@@status_out=@@refresh_time=@@process_exitstatus=@@cancellable=nil

  def self.get_output(refresh_period=5, tail_update=1, errors=1)
    # progress background color
    @@process_result_class = "process_result_ok"

    if @@process
      @@refresh_time = refresh_period
      @@process_tail += @@process.stdout_read(timeout: 0)
      if errors == 1
        @@process_tail += @@process.stderr_read(timeout: 0)
      end
      # sanitize the process output a bit
      @@process_tail = @@process_tail.gsub(/[<>]/, '<' => '&lt;', '>' => '&gt;')
      if tail_update == 1
        split = @@process_tail.split("\n",-1).collect { |nline| nline.split("\r",-1)[-1] }
        @@process_tail = (split[(-[10,split.size].min)..-1] or []).join("\n")
      end
      @@status_out = @@process_tail.split("\n").join("<br/>\n")
      if @@process.status[0] == "Z"
        @@process_exitstatus = @@process.reap.exitstatus
        
        @@process_exit = (_ :finished) + ": " + @@process_description + " - " + (_ :exited_with_status) + " " + @@process_exitstatus.to_s
        @@refresh_time = @@process = nil
        if @@process_exitstatus != 0
          @@process_result_class = "process_result_fail"
        end
      elsif @@process.runtime > @@process_timeout
        @@process.reap
        @@process_exit = (_ :timeout) + ": " + @@process_description + " - " + (_ :process_killed)
        @@refresh_time = @@process = nil
        @@process_result_class = "process_result_fail"
      end
      if @@process
        @@status_out = "<h1>" + @@process_description + "</h1><br/>\n" + @@status_out.force_encoding("UTF-8")
      else
        @@status_out = "<h1>" + @@process_exit + "</h1><br/>\n" + @@status_out.force_encoding("UTF-8")
      end
    end
    @@status_out = @@status_out
  end

  def self.clear()
    @@status_out.clear
  end

  def self.exists
    (@@status_out && @@status_out.size > 0)
  end

  def self.is_running
    @@process
  end

  def self.status_out
    @@status_out
  end

  def self.result_class
    @@process_result_class
  end

  def self.exit_status
    @@process_exitstatus
  end

  def self.refresh_time
    @@refresh_time
  end

  def self.cancellable
    @@cancellable
  end

  def self.cancel(signal=1)
    if @@process and @@cancellable
      @@process.reap(signal)
      @@refresh_time = @@process = nil
      @@process_result_class = "process_result_fail"
      @@process_exit = @@process_description + " - " + (_ :process_killed)
    end
  end

  def self.start(command, description, timeout, cancellable=0)
    return false if @@process
    @@cancellable = cancellable
    @@process_tail = ""
    @@process_description = description
    @@process_timeout = timeout
    @@process = ShellProcess.new(command)
  end

  def self.complete(command, tout=20, stime=0.1)
    process = ShellProcess.new(command)
    ret = process.stdout_read({ timeout: tout, sleeptime: stime }).strip
    raise Failed, command if process.reap.exitstatus != 0
    ret
  end
end
