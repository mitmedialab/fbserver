require 'resque'
require 'twitter'
require 'json'
require 'sqlite3'


class DataObject
  def initialize()
    @db = SQLite3::Database.new("db/development.sqlite3")
  end

  def save_account(account)
    if(@db.get_first_row("select 1 from accounts where screen_name='#{account.screen_name}'").nil?)
      @db.execute("insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at) values(?,?,?,?,?,?);", account.screen_name, account.name, account.profile_image_url, account.id, Time.now.to_s, Time.now.to_s)
    end
  end

  def save_friends(uid, all_follow_data)
    return nil if @db.get_first_row("select * from users where uid=#{uid} AND updated_at < DATE('now','-1 minute');").nil?
    friends = all_follow_data.collect{|account| account.attrs[:id]}.to_json
    @db.execute("update users set friends='#{friends}', updated_at=DATE('now') where uid = #{uid}");
    all_follow_data.collect{|account| self.save_account(account)}
  end

end

class ProcessUserFriends
  @queue = :fetchfriends

  def self.perform(authdata)
    # symbolise keys
    authdata.keys.each do |key|
      authdata[(key.to_sym rescue key) || key] = authdata.delete(key)
    end
    client = Twitter::Client.new(authdata)
    cursor = -1
    friendship_ids = []
    puts "fetching friendship ids"
    puts client.user.attrs[:id]
    while cursor != 0 do
      friendships = self.catch_rate_limit {
        client.friend_ids(client.user.attrs[:id], {:cursor=>cursor})
      }
      cursor = friendships.next_cursor
      friendship_ids.concat friendships.ids
      print "."
    end
    print " #{friendship_ids.size}"

    head = 0
    more = true
    follows = friendship_ids
    all_follow_data = []

    puts "fetching friendship data"
    while more
      if head + 100 > follows.size
        more = false
      end
      all_follow_data.concat self.catch_rate_limit{
        client.friendships(follows[head, 100])
      }
      head += 100
      print "."
    end
    print " #{all_follow_data.size}"

    all_follow_data.each do |account|
      puts "#{account.name}: @#{account.screen_name}: #{account.url}"
    end

   ### ==>
   db = DataObject.new
   db.save_friends(client.user.attrs[:id], all_follow_data)
  end

  def self.catch_rate_limit
    num_attempts = 0
    begin
      num_attempts += 1
      yield
    rescue Twitter::Error::TooManyRequests => error
      puts "RATE LIMITED"
      if num_attempts % 3 == 0
        sleep(error.rate_limit.reset_in)
        retry
      else
        retry
      end
    end
  end


end
