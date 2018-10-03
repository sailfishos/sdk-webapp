require 'json'
require './process.rb'

# A Tooling is simply a name to allow tooling operations
# All data is stored in the tooling install in sdk
# Refreshing is carried out by a systemd timer
class Tooling
  include Enumerable
  attr_accessor :name, :url, :installer_managed
  @@toolings=[]
  UPDATE_VALID_PERIOD=7200

  def id
    return @id
  end

  def initialize(name)
    @name = name
    @last_update_check=Time.at(0)
    @@toolings << self
    @id = @@toolings.size - 1
  end

  # Installs a tooling to the filesystem
  def create(url)
    CCProcess.start("sdk-manage --tooling --install '#{@name}' '#{url}'", (_ :adding_tooling) + " #{@name}", 60*60, 1)
  end

  # Removes a tooling from the fs
  def remove()
    CCProcess.start("sdk-manage --tooling --remove '#{@name}'", (_ :removing_tooling) + " #{@name}", 60*15)
    @@toolings.delete(@name)
  end

  # Is there a tooling set up already?
  def exists
    self.class.exists(@name)
  end

  def reset_check_time
    @last_update_check = Time.at(0)
  end

  # Is the cache out of date?
  def _update_check_needed
    (Time.now - @last_update_check) > UPDATE_VALID_PERIOD
  end

  # Force check what updates are available
  def _check_for_updates
    @update_info = CCProcess.complete("sdk-manage --tooling --upgradable '#{@name}'")
    @last_update_check = Time.now
  rescue CCProcess::Failed
    ""
  end

  def update_info
    if _update_check_needed then
      _check_for_updates
    end
    return @update_info
  end

  # Are any updates available
  def update_available?()
    update_info != ""
  end

  def update()
    CCProcess.start("sdk-manage --tooling --update '#{@name}'", (_ :syncing_tooling) + " #{@name}", 60*15)
    @last_update_check = Time.at(0)
  end

  def version
    _ :version_not_available
  end

  def refresh()
    CCProcess.start("sdk-manage --tooling --refresh '#{@name}'", (_ :refreshing_tooling) + " #{@name}", 60*15)
  end

  # Some class methods to handle iteration and save/load

  def self.load
    @@toolings = CCProcess.complete("sdk-manage --tooling --list --long").lines.map do |row|
      name, mode = row.chomp.split
      tooling = self.get(name)
      tooling.installer_managed = mode == "installer"
      tooling
    end
  rescue CCProcess::Failed
    @@toolings = []
  end

  def self.get(name)
    i = @@toolings.index {|t| t.name == name }
    if i == nil then
      new(name)
    else
      t=@@toolings[i]
      @@toolings[i]
    end
  end

  def self.exists(name)
    @@toolings.index {|t| t.name == name } != nil
  end

  def self.update_check_needed
    needed=false
    Tooling.each { |t| needed &&= t._update_check_needed }
    return needed
  end

  def self.check_for_updates
    Tooling.each do |t|
      t.check_for_updates
    end
  end

  def self.each
    for t in @@toolings do
      yield t
    end
  end

  def self.all
    @@toolings
  end

  def self.delete(id)
    @@toolings.delete_at(id.to_i)
  end

end
