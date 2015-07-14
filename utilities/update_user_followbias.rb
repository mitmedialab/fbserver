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
# Usage: ruby update_user_followbias.rb <LIMIT>
addendum = nil
if(ARGV.size>0)
  addendum = ARGV[0].to_i
end

user_counter = 0 
users = User.where("twitter_token IS NOT NULL and twitter_secret IS NOT NULL AND failed!=true")

if(!addendum.nil?)
  whitelist = User.where("treatment='test' OR treatment='ctl' or treatment='exp' or treatment='new' AND failed!=true ").limit(addendum)
else
  whitelist = User.where("treatment='test' OR treatment='ctl' or treatment='exp' or treatment='new' AND failed!=true ")
end


puts "whitelist #{whitelist.size}"

whitelist.each do |row|
  screen_name = row.screen_name
  twitter_id = row.uid

  if(row.twitter_token.nil? or row.twitter_secret.nil?)
    user_counter = 0 if(user_counter >= users.size)
    user = users[user_counter]
    user_counter += 1
  else
    user = row
  end
  
  authdata = {:consumer_key => ENV["TWITTER_CONSUMER_KEY"],
              :consumer_secret => ENV["TWITTER_CONSUMER_SECRET"],
              :oauth_token => user.twitter_token,
              :oauth_token_secret => user.twitter_secret,
              :api_user => user.screen_name,
              :followbias_user => twitter_id}
  Resque.enqueue(ProcessUserFriends, authdata)
  puts authdata
end
