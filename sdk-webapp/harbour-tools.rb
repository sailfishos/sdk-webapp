require 'json'
require './process.rb'

def harbour_visibility
  visible = File::exists?("/usr/lib/sdk-webapp-bundle/views/harbour_tools.haml")

  if visible == true
    return "normal"
  else
    return "none"
  end
end

class Harbour
  @@rpm_file=nil

  def id
    return @id
  end

  def self.validate(filename, basename)
    @@rpm_file=filename
    CCProcess.start("/usr/bin/rpmvalidation-wrapper.sh -d -u -r '#{filename}'", (_ :validating_rpm) + " #{basename}", 60*60)
  end

  def self.load
  end

  def self.filename
    @@rpm_file
  end

end
