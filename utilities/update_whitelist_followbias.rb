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

# OPTIONAL LIMIT ARGUMENT
# Usage: ruby update_user_followbias.rb <WHITELIST>

users = CSV.read(ARGV[0])

whitelist = []

users.each do |row|
  screen_name = row[0]
  user = User.find_by_screen_name(screen_name)
  next if user.nil?
#  puts user.screen_name
  whitelist << user
end

puts "whitelist #{whitelist.size}"

whitelist.each do |user|
  screen_name = user.screen_name
  twitter_id = user.uid

  api_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").limit(1)[0]

  #if(row.twitter_token.nil? or row.twitter_secret.nil?)
  #  user_counter = 0 if(user_counter >= users.size)
  #  user = users[user_counter]
  #  user_counter += 1
  #else
  #  user = row
  #end
  
  authdata = {:consumer_key => ENV["TWITTER_CONSUMER_KEY"],
              :consumer_secret => ENV["TWITTER_CONSUMER_SECRET"],
              :oauth_token => api_user.twitter_token,
              :oauth_token_secret => api_user.twitter_secret,
              :api_user => api_user.screen_name,
              :followbias_user => twitter_id}
  Resque.enqueue(ProcessUserFriends, authdata)
  puts authdata
end
