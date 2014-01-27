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
  @@updates=true
  @@beta=false

  def id
    return @id
  end

  def self.validate(filename, basename)
    do_updates=""
    do_beta=""

    if @@updates
      do_updates="-u"
    end

    if @@beta
      do_beta="--beta"
    end

    CCProcess.start("rpmvalidation-wrapper.sh -d #{do_updates} #{do_beta} -r #{filename}", (_ :validating_rpm) + " #{basename}", 60*60, 1)
  end

  def self.updates_readable
    _ (@@updates ? :harbour_updates_enabled : :harbour_updates_disabled)
  end

  def self.updates=(val)
    @@updates = val
  end

  def self.updates
    @@updates
  end

  def self.beta_readable
    _ (@@beta ? :harbour_beta_enabled : :harbour_beta_disabled)
  end

  def self.beta=(val)
    @@beta = val
  end

  def self.beta
    @@beta
  end

end
