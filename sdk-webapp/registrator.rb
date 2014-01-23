require 'json'
require './process.rb'


def registration_visibility

  regdomain=""

  domain=`sdk-register -d`

  if domain == ""
    return "none"
  end

  regdomain=File.open( "/etc/ssu/reg_domain" ).first if File::exists?( "/etc/ssu/reg_domain" )

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

end
