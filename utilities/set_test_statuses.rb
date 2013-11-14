require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'
require 'resque'
require 'resque-lock-timeout'

class ProcessUserFriends
  extend Resque::Plugins::LockTimeout
  @queue = "fetchfriends#{Rails.env}".to_sym
  @lock_timeout = 30
  def self.perform(authdata)
  end
end

statuslist = CSV.read(ARGV[0])

statuslist.each do |row|
  screen_name = row[0]
  user = User.find_by_screen_name(screen_name)
  next if user.nil?
  user.treatment = ARGV[1]
  user.save!
end
