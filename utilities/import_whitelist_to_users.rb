require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'
require 'resque'
require 'resque-lock-timeout'

class ProcessUserFriends
  extend Resque::Plugins::LockTimeout
  @queue = "followbias_#{Rails.env}".to_sym
  @lock_timeout = 30
  def self.perform(authdata)
  end
end

whitelist = CSV.read(ARGV[0])

whitelist.each do |row|
  screen_name = row[0]
  next if !User.find_by_screen_name(screen_name).nil?

  user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").limit(1)[0]
  
  authdata = {:consumer_key => ENV["TWITTER_CONSUMER_KEY"],
              :consumer_secret => ENV["TWITTER_CONSUMER_SECRET"],
              :oauth_token => user.twitter_token,
              :oauth_token_secret => user.twitter_secret,
              :api_user => user.screen_name,
              :followbias_user => screen_name}
  Resque.enqueue(ProcessUserFriends, authdata)
  puts authdata
end
