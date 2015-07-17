require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'twitter'

x = 0
User.where("twitter_token IS NOT NULL").each do |user|
  authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
              :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
              :oauth_token => user.twitter_token,
              :oauth_token_secret => user.twitter_secret}

  begin
    client = Twitter::Client.new(authdata)
    # check against the Twitter user, which is reliable
    # if the key doesn't work, this call should fail
    test = client.user("twitter") 
    user.failed = false
    user.save!
    print "o"
  rescue Twitter::Error::Unauthorized => error
    user.failed = true
    user.save!
    print "x"
  rescue Twitter::Error::TooManyRequests => error
    puts "RATE LIMITED"
    sleep(error.rate_limit.reset_in)
  end
end
