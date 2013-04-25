require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'models', 'name_gender.rb')

require 'twitter'
require 'csv'

##
## sometimes, the Twitter gem fails when someone follows an account
## that has been banned. This script cleans up that situation
## it doesn't need to be run that frequently

@name_gender = NameGender.new
all_accounts_to_correct = []

user = User.find_by_screen_name(ARGV[0])
authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
            :oauth_token => user.twitter_token,
            :oauth_token_secret => user.twitter_secret}

client = ProcessUserFriends.catch_rate_limit{
  Twitter::Client.new(authdata)
}

User.all.each do |user|
  next if user.friendsrecords.last.nil?
  next if user.friendsrecords.last.friends == ""
  missing_users = []
  begin
    #print "."
    missing_users = JSON.load(user.friendsrecords.last.friends).collect do |friend_id|
      friend_id if Account.find_by_uuid(friend_id).nil?
    end.compact
  rescue JSON::ParserError
    #print " #{user.screen_name} "
  end

  if(missing_users.size>0)
    puts "#{user.screen_name} "
    puts "   #{missing_users}"
  end
  
  missing_users.each do |mu|
    ta = ProcessUserFriends.catch_rate_limit{
      client.user(mu.to_i)  
    }
    if(ta and ta != [] and Account.find_by_uuid(mu).nil?)

      a = Account.create!(:screen_name=>ta.screen_name, :name=>ta.name,
                          :profile_image_url=>ta.profile_image_url,
                          :gender=>@name_gender.process(ta.name),
                          :uuid=>mu)
      a.save!
      puts "  #{a.screen_name}"
    else
      puts "  #{mu}"
    end
  end
end
