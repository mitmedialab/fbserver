require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'
require 'resque'

userlist = CSV.read(ARGV[0])

userlist.each do |row|
  screen_name = row[0]
  user = User.find_by_screen_name(screen_name)
  next if user.nil?
end
