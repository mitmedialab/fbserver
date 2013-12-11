# -*- encoding : utf-8 -*-
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')
require 'resque'
require 'twitter'
require 'json'
require 'mysql2'
require File.join(File.dirname(__FILE__), '../models/name_gender.rb')


class DataObject
  def initialize()
    #TODO: key to rails env
    @db = Mysql2::Client.new(:host => "localhost", :username => "fbserver", :database=>"fbserverdev_development")
    #@db = Mysql.new("localhost", "fbserver", "", "fbserver_development")
    #@db = SQLite3::Database.new(File.join(File.dirname(__FILE__), "../../db/development.sqlite3"))
    @name_gender = NameGender.new
    @system_user = User.find_by_screen_name("FollowBias System")
  end

  def user_exists? screen_name
    @db.query("select 1 from users where screen_name='#{screen_name}'").size > 0
  end

  def create_user t
    @db.query("INSERT into users(screen_name, name, uid, created_at, updated_at, provider) VALUES('#{t.screen_name}', \"#{t.name.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub(/"/,'""')}\",'#{t.id}','#{Time.now.to_s}', '#{Time.now.to_s}', 'twitter');")
  end

  def strip_redundant_accounts id_list
    more = true
    head = 0
    return_list = []
    while more
      if head + 100 > id_list.size
        more = false
      end

      break if id_list[head, 100].size == 0
     
      query = "select uuid from accounts WHERE uuid IN (#{id_list[head, 100].join(",")});"
      #puts query
      rows = @db.query(query).collect{|x|x['uuid']}

      id_list[head, 100].each do |id|
        return_list << id unless rows.include? id
      end
      head += 100
    end
    return_list
  end

  def save_account(account)
    #begin
    print "."
      if(@db.query("select 1 from accounts where screen_name='#{account.screen_name}'").size == 0)
      gender = @name_gender.process(account.name)[:result]
        #@db.execute("insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender) values(?,?,?,?,?,?,?);", account.screen_name, account.name, account.profile_image_url, account.id, Time.now.to_s, Time.now.to_s, @name_gender.process(account.name)[:result])
        query = "insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender) values('#{account.screen_name}', \"#{account.name.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub(/"/,'""')}\", '#{account.profile_image_url}', '#{account.id}', '#{Time.now.to_s}', '#{Time.now.to_s}', '#{gender}')"
        @db.query(query)
        rails_acct = Account.find_by_screen_name(account.screen_name)
        judgment = @system_user.account_gender_judgments.create({:account_id => rails_acct.id, :gender=> gender})
      end
    #end
  end

  def save_friends(uid, all_follow_data, friends)
    puts "SAVING FRIENDS #{uid}"
    #friends = all_follow_data.collect{|account| account.attrs[:id]}.to_json
    all_follow_data.each{|account| self.save_account(account)}
    user_id = @db.query("select id from users where uid=#{uid}").first["id"]
    query = "insert into friendsrecords(user_id, friends, created_at, updated_at) values(#{user_id}, '#{friends.to_json}',NOW(),NOW());"
 
    #puts query
    @db.query(query)
  end

  def too_soon followbias_user
    query = "select 1 from users join friendsrecords on users.id = friendsrecords.user_id where users.uid=#{followbias_user.attrs[:id]} AND friendsrecords.created_at > (NOW() - INTERVAL 350 MINUTE);"
    #puts query
    @db.query(query).size > 0
  end

end

class ProcessUserFriends
  @queue = "fetchfriends#{Rails.env}".to_sym

  def self.perform(authdata)
    db = DataObject.new


    # symbolise keys
    authdata.keys.each do |key|
      authdata[(key.to_sym rescue key) || key] = authdata.delete(key)
    end

    puts "connecting to client"
    client = self.catch_rate_limit{
      Twitter::Client.new(authdata)
    }

    if(!authdata[:followbias_user].nil?)
      followbias_user = client.user(authdata[:followbias_user])
      if(!db.user_exists? followbias_user.screen_name)
        db.create_user(followbias_user)
      end
    else
      followbias_user = client.user
    end


    if db.too_soon followbias_user
      puts "TOO SOON"
      return nil
    end

    cursor = -1
    friendship_ids = []
    puts "fetching friendship ids"
    #puts followbias_user.attrs[:id]


    while cursor != 0 do
      friendships = self.catch_rate_limit {
        client.friend_ids(followbias_user.attrs[:id], {:cursor=>cursor})
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
    puts "fetching friendship data for #{follows.size} accounts"

    all_follow_data = []

    puts "fetching friendship data"
    while more
      if head + 100 > new_follows.size
        more = false
      end

      break if new_follows.size == 0

      puts "new follows: #{new_follows[head, 100]}"

      all_follow_data.concat self.catch_rate_limit{
        client.users(new_follows[head, 100], :method => :post)
      }
      head += 100
      print "."
    end
    print " #{all_follow_data.size}"

    #all_follow_data.each do |account|
    #  puts "#{account.name}: @#{account.screen_name}: #{account.url}"
    #end

   ### ==>
   db.save_friends(followbias_user.attrs[:id], all_follow_data, follows)
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
    rescue Twitter::Error::NotFound => error
      puts "Twitter::Error:NotFound -- retrying"
      puts error
      #return nil after second attempt
      return [] if(num_attempts >= 2)
      sleep(8)
      retry
    rescue Twitter::Error::Forbidden => error
      return []
    rescue Twitter::Error::ServiceUnavailable => error
      puts "Twitter::Error:ServiceUnavailable -- retrying"
      puts error
      sleep(8)
      retry
    rescue Twitter::Error::BadGateway => error
      puts "Twitter::Error:BadGateway -- retrying"
      puts error
      sleep(8)
      retry
    end
  end

end
