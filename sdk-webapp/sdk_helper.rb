require './shell_process'
require './providers.rb'
require './targets.rb'
require './toolings.rb'
require './engine.rb'
require './process.rb'
require './flash.rb'
require './registrator.rb'
require './harbour_tools.rb'

I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
I18n::Backend::Simple.send(:include, I18n::Backend::TS)
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.default_locale = 'en'
I18n.load_path << Dir[ "./i18n/*.ts" ]
I18n.locale = 'en'

def _(*args)
  I18n.t(*args)
end

# initialize the following classes with data
Tooling.load
Target.load
Harbour.load

class SdkHelper < Sinatra::Base

  use Rack::MethodOverride #this is needed for delete methods

  get "/index.css" do
    sass :index
  end

  get '/' do redirect to "/"+system_language+"/targets/"; end
  get '/targets/' do redirect to "/"+system_language+"/targets/"; end
  get '/updates/' do redirect to "/"+system_language+"/updates/"; end
  get '/register_sdk/' do redirect to "/"+system_language+"/register_sdk/"; end
  get '/harbour_tools/' do redirect to "/"+system_language+"/harbour_tools/"; end

  # the /? matches the url with or without the trailing /
  get '/:locale/?' do
    locale_set
    CCProcess.get_output
    haml :targets, :locals => { :tab => :targets }
  end

# register_sdk
  get '/:locale/register_sdk/?' do
    locale_set
    CCProcess.get_output
    haml :register_sdk, :locals => { :tab => :register_sdk }
  end

  post '/:locale/register_sdk/do_register' do
    name = params[:username]
    pass = params[:password]
    registrator = Registrator.new(name, pass)
    registrator.register
    redirect back
  end

# harbour_tools
  get '/:locale/harbour_tools/?' do
    locale_set
    # update every 3 seconds, no tail updates, no stderr, ansi colors
    CCProcess.get_output(3, 0, 0, 1)
    haml :harbour_tools, :locals => { :tab => :harbour_tools }
  end

  post '/:locale/harbour_tools/validate_rpm' do
    if params[:rpm_name].nil?
      Flash.to_user _(:choose_rpm)
    else
      # + chars in filename have been converted to spaces, let's
      # convert them back
      fname = params[:rpm_name][:filename].tr(' ', '+')
      # use a path accessible to sb2
      tmpdir = Dir.home + "/.cache/sdk-webapp"
      FileUtils.mkpath(tmpdir)
      File.rename(params[:rpm_name][:tempfile], tmpdir + "/" + fname)
      target = params[:target]
      suites = params[:suites][target]
      Harbour.validate(tmpdir + "/" + fname, fname, target, suites)
    end
    redirect back
  end

  post '/:locale/harbour_tools/config' do
    locale_set
    if params[:updates]
      Harbour.updates=!(params[:updates] == "true")
      { value: Harbour.updates_readable, state: Harbour.updates }.to_json
    elsif params[:beta]
      Harbour.beta=!(params[:beta] == "true")
      { value: Harbour.beta_readable, state: Harbour.beta }.to_json
    end
  end

# updates
  get '/:locale/updates/?' do
    locale_set
    CCProcess.get_output
    haml :updates, :locals => { :tab => :updates }
  end

  post '/:locale/provider/add' do
    locale_set
    Provider.new(params[:provider_name], params[:provider_url])
    Provider.save
    redirect to("/"+params[:locale]+'/updates/')
  end

  delete '/:locale/provider/:provider_id' do
    locale_set
    Provider.delete(params[:provider_id])
    Provider.save
    redirect back
  end

  # force a repository refresh
  post '/:locale/updates/refresh' do
    refresh_repositories
    redirect back
  end

  #update sdk
  post '/:locale/updates/engine' do
    Engine.update()
    redirect back
  end

  #clear the operation progress output
  post '/actions/clear_output' do
    CCProcess.clear
    redirect back
  end

  # stop a background process
  post '/actions/cancel_process' do
    CCProcess.cancel
    redirect back
  end

# toolings
  #remove tooling
  delete '/:locale/toolings/:tooling' do
    Tooling.get(params[:tooling]).remove
    redirect back
  end

  #update tooling
  post '/:locale/toolings/:tooling/update' do
    Tooling.get(params[:tooling]).update
    redirect back
  end

# targets
  get '/:locale/targets/?' do
    if ! CCProcess.is_running
      # if a process is running, this is not useful
      Tooling.load
      Target.load
    end
    locale_set
    CCProcess.get_output
    haml :targets, :locals => { :tab => :targets }
  end

  get '/:locale/targets/:target' do
    @target = params[:target]
    locale_set
    CCProcess.get_output
    packages_list_update
    haml :target, :locals => { :tab => :targets }
  end

  #add target
  post '/:locale/targets/add' do
    if params.has_key?("template_id") then
      if params[:template_id].to_i < 0
        Flash.to_user _(:please_select_a_preconfigured_target)
        redirect back
        return
      end
      t = Provider.targetTemplates[params[:template_id].to_i]
      url = t['url']
      name = params[:local_target_name]
      name = t['name'] if name == ''
      tooling_url = t['tooling_url']
      tooling_name = t['tooling_name']
      toolchain = t['toolchain']
    else
      name = params[:target_name]
      url = params[:target_url]
      tooling_name = params[:tooling_name]
      tooling_url = params[:tooling_url]
      toolchain = params[:toolchain]
      if name == '' or url == ''
        Flash.to_user _(:target_required_parameter_missing)
        redirect back
        return
      end
    end

    if ! Target.exists(name) then
      target = Target.get(name)
      target.create(url, tooling_name, tooling_url, toolchain)
    else
      Flash.to_user _(:target_already_present, name: name)
    end
    redirect back
  end

  #remove target
  delete '/:locale/targets/:target' do
    Target.get(params[:target]).remove
    redirect back
  end

  #refresh target
  post '/:locale/targets/:target/refresh' do
    Target.get(params[:target]).refresh
    redirect back
  end

  #sync target
  post '/:locale/targets/:target/sync' do
    Target.get(params[:target]).sync
    redirect back
  end

  #update target
  post '/:locale/targets/:target/update' do
    Target.get(params[:target]).update
    redirect back
  end

  #install a list of packages
  post '/:locale/targets/:target/packages' do
    locale_set
    target = params[:target]
    if params[:pkglist]
      packages = params[:pkglist]
      package_install(target, packages)
    end
    redirect back
  end

  # remove a list of packages
  post '/:locale/targets/:target/delete_packages' do
    locale_set
    target = params[:target]
    if params[:pkglist]
      packages = params[:pkglist]
      package_remove(target, packages)
    end
    redirect back
  end


  # info
  get '/:locale/info/?' do
    content_type 'text/plain'
    ["df -h", "rpmquery -qa|sort", "cat /proc/version", "/sbin/ifconfig -a", "/sbin/route -n", "mount", "zypper lr", "ping -c 4 releases.sailfishos.org", "free"].map { |command|
      ["*"*80,command,"\n", CCProcess.complete(command), "\n"] rescue Exception
    }.flatten.map { |line| line.to_s }.join("\n")
  end

  helpers do

    def locale_set
      @language = I18n.locale = params[:locale]
    end

    def system_language
      if ENV['LANG']
        ENV['LANG'].split("_")[0]
      else
        'C'
      end
    end

    def refresh_repositories
      begin
        CCProcess.complete("sdk-manage --refresh-all", 60, 1)
      rescue CCProcess::Failed
      end
      Engine.reset_check_time
      Tooling.each do |t|
        t.reset_check_time if not t.nil?
      end
      Target.each do |t|
        t.reset_check_time if not t.nil?
      end
      # also reset the providers check time to force rechecking of URL
      # validity
      Provider.reset_check_time
    end

    # -------------------------------- Packages

    def packages_list_update
      @target = params[:target]
      $package_list = @package_list = CCProcess.complete("sdk-manage --devel --list #@target").split.map {|line| line.split(',')}.map {|i,j| [i, j == 'i']}
    rescue CCProcess::Failed
      @package_list = ($package_list or []) #FIXME: nil if can't read the list!
    end

    def package_install(target, packages)
      CCProcess.start("sdk-manage --devel --install '#{target}' #{packages}", (_ :installing_packages), 60*60)
    end

    def package_remove(target, packages)
      CCProcess.start("sdk-manage --devel --remove '#{target}' #{packages}", (_ :removing_packages), 60*60)
    end
  end

end
