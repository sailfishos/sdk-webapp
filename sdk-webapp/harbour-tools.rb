require 'json'
require './process.rb'

def harbour_visibility
  visible = File::exists?("/usr/lib/sdk-webapp-bundle/views/harbour_tools.haml")

  if visible
    return "normal"
  else
    return "none"
  end
end

class Harbour
  @@rpm_file=nil
  @@updates=true

  def id
    return @id
  end

  def self.validate(filename, basename)
    @@rpm_file=filename
    do_updates=""
    if @@updates
      do_updates="-u"
    end

    CCProcess.start("/usr/bin/rpmvalidation-wrapper.sh -d #{do_updates} -r #{filename}", (_ :validating_rpm) + " #{basename}", 60*60)
  end

  def self.load
  end

  def self.toggle_updates
    @@updates=! @@updates
    return ""
  end

  def self.updates
    if @@updates == true
      return (_ :harbour_updates_enabled)
    else
      return (_ :harbour_updates_disabled)
    end
  end

  def self.filename
    @@rpm_file
  end

end

def harbour_toggle_updates
  Harbour.toggle_updates
end

