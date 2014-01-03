# -*- encoding : utf-8 -*-
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')
require 'resque'
require 'twitter'
require 'json'
require 'mysql2'
require 'curb'
require File.join(File.dirname(__FILE__), '../models/name_gender.rb')


#class TestScheduleTask
#  @queue = "test_schedule_#{Rails.env}".to_sym
#
#  def self.perform arg
#    puts "#{arg}: #{Time.now}"
#  end
#end

# run through and update the followbias cache 
# no more frequently than every 10 minutes
class CacheFollowBiasRecords
  @queue = "followbias_#{Rails.env}".to_sym
  
  def self.perform
    count = 0 
    User.all.each do |user|
      if(user.followbias_records.count == 0 or
         user.followbias_records.order("created_at ASC").last.created_at <= 10.minutes.ago)
        print "."
        #print "#{user.screen_name} "
        count += 1
        user.cache_followbias_record
      else
        print "x"
      end
    end
    Rails.logger.info "Attempted to cache followbias for #{count} "
  end
end

class UpdateFollowBiasForAllUsers
  @queue = "followbias_#{Rails.env}".to_sym
  
  def self.perform
    user_counter = 0

    # note that we omit people who have revoked our access
    whitelist = User.where("treatment='test' OR treatment='ctl' or treatment='exp' or treatment='new' or treatment='alpha'")

    whitelist.each do |row|
      screen_name = row.screen_name
      user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").limit(1)[0]

      authdata = {:consumer_key => ENV["TWITTER_CONSUMER_KEY"],
                  :consumer_secret => ENV["TWITTER_CONSUMER_SECRET"],
                  :oauth_token => user.twitter_token,
                  :oauth_token_secret => user.twitter_secret,
                  :api_user => user.screen_name,
                  :followbias_user => screen_name}
      Resque.enqueue(ProcessUserFriends, authdata)
    end
    Rails.logger.info "Queued Twitter updates for #{whitelist.size} accounts"
    puts "Queued Twitter updates for #{whitelist.size} accounts"
  end
end

class DataObject
  attr_reader :system_user
  def initialize()
    #TODO: key to rails env
    @db = Mysql2::Client.new(:host => "localhost", :username => "fbserver", :database=>"fbserver_#{Rails.env}")
    #@db = Mysql.new("localhost", "fbserver", "", "fbserver_development")
    #@db = SQLite3::Database.new(File.join(File.dirname(__FILE__), "../../db/development.sqlite3"))
    @name_gender = NameGender.new
    @system_user = User.find_by_screen_name("FollowBias System")
  end

  def user_exists? screen_name
    @db.query("select 1 from users where screen_name='#{screen_name}'").size > 0
  end

  def block_api_user a
    puts "blocking failed user"
    @db.query("UPDATE users set failed=true WHERE screen_name = '#{a[:api_user]}';")
  end

  def count_stale_profile_image_accounts
    @db.query("SELECT COUNT(*) from accounts WHERE profile_image_updated_at IS NULL or profile_image_updated_at < NOW() - INTERVAL 1 WEEK")
  end

  def fetch_100_stale_profile_image_accounts_and_flag
    uuids = @db.query("SELECT uuid from accounts WHERE profile_image_updated_at IS NULL or profile_image_updated_at < NOW() - INTERVAL 1 WEEK LIMIT 100").each(:as=> :array).collect{|i|i[0]}
    query = "UPDATE accounts SET profile_image_updated_at = NOW() WHERE "
    uuids.each do |uuid|
      query += "uuid='#{uuid}' or "
    end
    query = query[0,query.size - 3] + ";"
    @db.query(query)
    uuids
  end

  def update_accounts accounts
    query = ""
    accounts.each do |account|
      query ="UPDATE accounts SET profile_image_url='#{@db.escape(account.profile_image_url)}', screen_name='#{@db.escape(account.screen_name)}', profile_image_updated_at= NOW(), updated_at = NOW() WHERE uuid = '#{account.id}'; "
      print "."
      @db.query(query)
    end
    #puts query
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
      if(@db.query("select 1 from accounts where screen_name='#{account.screen_name}'").size == 0)
        #@db.execute("insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender) values(?,?,?,?,?,?,?);", account.screen_name, account.name, account.profile_image_url, account.id, Time.now.to_s, Time.now.to_s, @name_gender.process(account.name)[:result])
        gender = @name_gender.process(account.name)[:result]
        query = "insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender, profile_image_updated_at) values('#{account.screen_name}', \"#{account.name.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub(/"/,'""')}\", '#{account.profile_image_url}', '#{account.id}', '#{Time.now.to_s}', '#{Time.now.to_s}', '#{gender}', NOW())"
        @db.query(query)

        #puts "CREATING AUTO RECORD"
        rails_acct = Account.find_by_screen_name(account.screen_name)
        #puts rails_acct.screen_name
        #puts @system_user.screen_name
        #puts @system_user.account_gender_judgments.size
        #puts gender
        @system_user = User.find_by_screen_name("FollowBias System") if @system_user.nil?
        judgment = @system_user.account_gender_judgments.create({:account_id => rails_acct.id, :gender=> gender})
        #puts judgment
        print "o"
      else
        print "."
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

module CatchTwitterRateLimit
  def self.included base
    base.extend CatchRateLimit
  end

  module CatchRateLimit
    def catch_rate_limit(authdata, db)
      num_attempts = 0
      begin
        num_attempts += 1
        yield
      rescue Twitter::Error::InternalServerError => error
        puts error
        return [] if(num_attempts >= 2)
        retry
      rescue Twitter::Error::ClientError => error
        puts error
        return [] if(num_attempts >= 2)
        retry
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
        puts "blocking #{authdata[:api_user]}"
        db.block_api_user(authdata)
        return []
      rescue Twitter::Error::Unauthorized => error
        return [] if(num_attempts >= 2)
        puts "Unauthorized: #{error} -- retrying with a different token"
        db.block_api_user(authdata)
        current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
        authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                    :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                    :oauth_token => current_user['twitter_token'],
                    :oauth_token_secret => current_user['twitter_secret'],
                    :api_user => current_user.screen_name}
        client = Twitter::Client.new
        retry
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
end

class FindExpiredTwitterIcons
  include CatchTwitterRateLimit
  @queue = "followbias_test_#{Rails.env}".to_sym
  def self.perform
    db = DataObject.new
    puts "updating accounts"
    while(db.count_stale_profile_image_accounts.count > 0)
 
      # connect to Twitter using a random user
      # TODO: at some time, archive the rate limits
      # and intelligently allocate API users
      current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
      authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                  :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                  :oauth_token => current_user['twitter_token'],
                  :oauth_token_secret => current_user['twitter_secret'],
                  :api_user => current_user.screen_name}
      client = self.catch_rate_limit(authdata, db){
        Twitter::Client.new(authdata)
      }
      
      #fetch 100 UUIDs of possibly stale profile images from the accounts table
      uuids = db.fetch_100_stale_profile_image_accounts_and_flag
      users = self.catch_rate_limit(authdata, db){
       client.users(uuids)
      }
      if(users.size>0)
        db.update_accounts(users)
        print "."
      else
        print "x"
      end
    end
  end
end

class ProcessUserFriends
  include CatchTwitterRateLimit
  @queue = "followbias_#{Rails.env}".to_sym
  #@queue = "fetchfriends#{Rails.env}".to_sym

  def self.perform(authdata)
    db = DataObject.new


    # symbolise keys
    authdata.keys.each do |key|
      authdata[(key.to_sym rescue key) || key] = authdata.delete(key)
    end

    puts "connecting to client"
    client = self.catch_rate_limit(authdata, db){
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


    error_count = 0;
    while cursor != 0 do
      friendships = self.catch_rate_limit(authdata, db) {
        client.friend_ids(followbias_user.attrs[:id], {:cursor=>cursor})
      }
      #make sure friendships is a valid 
      if friendships and friendships.class.name!="Array"
        cursor = friendships.next_cursor
        friendship_ids.concat friendships.ids
        print "."
      else
        #just to be sure, try one more time if the Twitter API Exceptions fire
        if error_count >= 1
          error_count = 0
          cursor = 0
        else
          error_count +=1
          puts "Twitter API error. Trying again"
        end
      end
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

      all_follow_data.concat self.catch_rate_limit(authdata, db){
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

end
