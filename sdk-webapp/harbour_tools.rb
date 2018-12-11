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

class Suite
  attr_accessor :target_name, :id, :name, :essential, :website

  def initialize(target_name, id)
    @target_name = target_name
    @id = id
    @name = ""
    @essential = true
    @website = ""
  end
end

class Harbour
  @@updates=true
  @@beta=false
  @@suites=[]

  def id
    return @id
  end

  def self.validate(filename, basename, target, suites)
    do_updates=""
    do_beta=""

    if @@updates
      do_updates="-u"
    end

    if @@beta
      do_beta="--beta"
    end

    CCProcess.start("rpmvalidation-wrapper.sh #{do_updates} #{do_beta} -r '#{filename}' #{target} #{suites.join(' ')}", (_ :validating_rpm) + " #{basename}", 60*60, 1)
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

  def self.load
    @@suites = CCProcess.complete("rpmvalidation-wrapper.sh --list-suites").lines.map do |row|
      target_name, id, essential, website, name = row.chomp.split(/\s+/, 5)
      suite = self.suite(target_name, id)
      suite.essential = essential.downcase == "essential"
      suite.website = website != "-" ? website : ""
      suite.name = name
      suite
    end
  rescue CCProcess::Failed
    @@suites = []
  end

  def self.suite(target_name, id)
    i = @@suites.index {|s| s.target_name == target_name and s.id == id }
    if i == nil then
      Suite.new(target_name, id)
    else
      s=@@suites[i]
      @@suites[i]
    end
  end

  def self.suites(target_name)
    @@suites.select { |s| s.target_name == target_name }
  end
end
