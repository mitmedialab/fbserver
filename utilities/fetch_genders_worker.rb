require '../config/environment'
require 'twitter'
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')

user = User.find_by_screen_name ARGV[1]
subject_name = ARGV[0]
if user.nil?
  puts "can't find auth user"
  exit
end

authdata = {:consumer_key => ENV["TWITTER_CONSUMER_KEY"],
            :consumer_secret => ENV["TWITTER_CONSUMER_SECRET"],
            :oauth_token => user.twitter_token,
            :oauth_token_secret => user.twitter_secret}

twitter = Twitter::Client.new(authdata)
db = DataObject.new

subject = ProcessUserFriends.catch_rate_limit{
  twitter.user(subject_name)
}

#subject.class.send(:include, Twitter::API::FriendsAndFollowers)

if subject.nil?
  print "Subject not found. Exiting..."
  exit
end

puts "fetching friendship ids"
cursor = -1
friendship_ids = []
while cursor != 0 do
  friendships = ProcessUserFriends.catch_rate_limit {
    #twitter.friend_ids(subject.attrs[:id], {:cursor=>cursor})
    twitter.follower_ids(subject.attrs[:id], {:cursor=>cursor})
  }
  cursor = friendships.next_cursor
  friendship_ids.concat friendships.ids
  print "."
end
print " #{friendship_ids.size}"

head = 0
more = true
follows = friendship_ids

puts "checking redundant accounts"
new_follows = db.strip_redundant_accounts follows

puts "fetching friendship data for #{new_follows.size} accounts"
while more
  if head + 100 > new_follows.size
    more = false
  end

  break if new_follows.size == 0

  follow_data =  ProcessUserFriends.catch_rate_limit{
    twitter.users(new_follows[head, 100])
  }

  follow_data.each do |u|
    db.save_account(u)
  end
  head += 100
  print "."
end
