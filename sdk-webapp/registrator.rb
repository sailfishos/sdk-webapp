require 'json'
require './process.rb'

def registration_visibility

  domain="foo",raw_domain="",
  regdomain="", raw_regdomain=""

  raw_domain=`sdk-register -d`
  unless raw_domain == nil
    domain=raw_domain[0,raw_domain.length-1]
  end
  
  raw_regdomain=File.open( "/etc/ssu/reg_domain" ).first if File::exists?( "/etc/ssu/reg_domain" )
  unless raw_regdomain == nil
    regdomain=raw_regdomain[0,raw_domain.length-1]
  end

  if domain==regdomain
    return "normal"
  else
    return "none"
  end
end

class Registrator

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
