require 'json'
require './process.rb'

class Registrator

# some weird general parameters
  UPDATE_VALID_PERIOD=7200

  def id
    return @id
  end

  def initialize(username, password)
      @ssu_username=username
      @ssu_password=password
  end

  def register
    CCProcess.start("sdk-manage --register-all --user '#{@ssu_username}' --password '#{@ssu_password}'", (_ :registering) + " #{@ssu_username}", 60*60 )
  end

  def self.load
  end

end