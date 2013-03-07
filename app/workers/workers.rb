require 'resque'
require 'twitter'
require 'json'
require 'sqlite3'
require File.join(File.dirname(__FILE__), '../models/name_gender.rb')


class DataObject
  def initialize()
    @db = SQLite3::Database.new("db/development.sqlite3")
    @name_gender = NameGender.new
  end

  def strip_redundant_accounts id_list
    more = true
    head = 0
    return_list = []
    while more
      if head + 100 > id_list.size
        more = false
      end
      rows = @db.execute("select id from accounts WHERE id IN (#{id_list[head, 100].join(",")});").collect {|x|x[0]}

      puts "#{rows.size} rows returned"
      id_list[head, 100].each do |id|
        return_list << id unless rows.include? id
      end
      head += 100
    end
    return_list
  end

  def save_account(account)
    puts "SAVE ACCT"
    if(@db.get_first_row("select 1 from accounts where screen_name='#{account.screen_name}'").nil?)
      puts account.screen_name
      @db.execute("insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender) values(?,?,?,?,?,?,?);", account.screen_name, account.name, account.profile_image_url, account.id, Time.now.to_s, Time.now.to_s, @name_gender.process(account.name)[:result])
    end
  end

  def save_friends(uid, all_follow_data)
    #return nil if @db.get_first_row("select * from users where uid=#{uid} AND updated_at < DATE('now','-1 minute');").nil?
    puts "SAVING FRIENDS"
    friends = all_follow_data.collect{|account| account.attrs[:id]}.to_json
    all_follow_data.each{|account| self.save_account(account)}
    @db.execute("update users set friends='#{friends}', updated_at=DATE('now') where uid = #{uid}");
  end

end

class ProcessUserFriends
  @queue = :fetchfriends

  def self.perform(authdata)
    db = DataObject.new
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

    puts "checking redundant accounts"
    follows = db.strip_redundant_accounts follows
    puts "fetching friendship data for #{follows.size} accounts"

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
   db.save_friends(client.user.attrs[:id], all_follow_data)
   puts "FRIENDS SAVED"
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
