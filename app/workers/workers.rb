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
    User.where("treatment!='new'").find_each do |user|
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
    puts
    Rails.logger.info "Attempted to cache followbias for #{count} "
  end
end

class UpdateFollowBiasForAllUsers
  @queue = "followbias_#{Rails.env}".to_sym
  
  def self.perform
    user_counter = 0

    # note that we omit people who have revoked our access
    whitelist = User.where("treatment='test' OR treatment='ctl'")# or treatment='exp' or treatment='new' or treatment='alpha' or treatment LIKE '%test%' or treatment LIKE '%ctl%'")

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
      query ="UPDATE accounts SET profile_image_url='#{@db.escape(account.profile_image_url)}', screen_name='#{@db.escape(account.screen_name)}', profile_image_updated_at= NOW(), updated_at = NOW() WHERE uuid = #{account.id}; "
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
    page_size = 200
    return_list = []
    while more
      if head + page_size > id_list.size
        more = false
      end

      break if id_list[head, page_size].size == 0
     
      query = "select uuid from accounts WHERE uuid IN (#{id_list[head, page_size].join(",")});"
      #puts query
      rows = @db.query(query).collect{|x|x['uuid']}

      return_list = return_list + id_list[head,page_size] - rows
      #previous line is an experimental optimization is necessary, we can use list subtraction here
      #id_list[head, page_size].each do |id|
      #  return_list << id unless rows.include? id
      #end
      head += page_size
    end
    return_list
  end

  def save_account(account)
    #begin
      #if(@db.query("select 1 from accounts where screen_name='#{account.screen_name}'").size == 0)
      account_id = account.id
      #puts account.screen_name
      if(@db.query("select 1 from accounts where uuid=#{account.id}").size == 0)
        #@db.execute("insert into accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender) values(?,?,?,?,?,?,?);", account.screen_name, account.name, account.profile_image_url, account.id, Time.now.to_s, Time.now.to_s, @name_gender.process(account.name)[:result])
        gender = @name_gender.process(account.name)[:result]
        query = "INSERT INTO accounts(screen_name, name, profile_image_url, uuid, created_at, updated_at, gender, profile_image_updated_at) values('#{account.screen_name}', \"#{account.name.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub(/"/,'""')}\", '#{account.profile_image_url}', #{account.id}, '#{Time.now.to_s}', '#{Time.now.to_s}', '#{gender}', NOW())"
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

  def save_friends(uid, all_follow_data, friends, twitter_user)
    puts "SAVING FRIENDS #{uid}"
    #friends = all_follow_data.collect{|account| account.attrs[:id]}.to_json
    all_follow_data.each{|account| self.save_account(account)}

    # strip recent tweets to save storage
    twitter_dict = JSON.load(twitter_user.to_json).to_json(:except=>'status') 

    user_id = @db.query("select id from users where uid=#{uid}").first["id"]
    query = "insert into friendsrecords(user_id, friends, twitter_json, created_at, updated_at) values(#{user_id}, '#{friends.to_json}','#{Mysql.escape_string(twitter_dict.to_json)}',NOW(),NOW());"
 
    #puts query
    @db.query(query)
  end

  def too_soon followbias_user
    query = "select screen_name from users join friendsrecords on users.id = friendsrecords.user_id where users.uid=#{followbias_user.attrs[:id]} AND friendsrecords.created_at > (NOW() - INTERVAL 350 MINUTE);"
    # TEMP QUERY
    #query = "select screen_name from users join friendsrecords on users.id = friendsrecords.user_id where users.uid=#{followbias_user.attrs[:id]} AND friendsrecords.created_at > (NOW() - INTERVAL 80 MINUTE);"
    #puts query
    @db.query(query).size > 0
  end

end

module CatchTwitterRateLimit
  def self.included base
    base.extend CatchRateLimit
  end

  module CatchRateLimit
    def catch_rate_limit(authdata, db, sleep_seconds=8)
      num_attempts = 0
      begin
        #print "crl2 "
        num_attempts += 1
        yield
      rescue Twitter::Error::Unauthorized => error
        puts "Unauthorized: #{error} -- retrying with a different token"
        # If the blocking is overzealous, you can run
        # utilities/update_key_freshness_status.rb
        #db.block_api_user(authdata)
        # skipping blocks for now until I can make sure it's not overzealous
        return [] if(num_attempts >= 4)
        current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
        authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                    :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                    :oauth_token => current_user['twitter_token'],
                    :oauth_token_secret => current_user['twitter_secret'],
                    :api_user => current_user.screen_name}
        $client = Twitter::Client.new(authdata)
        sleep(sleep_seconds)
        retry
      rescue Twitter::Error::InternalServerError => error
        puts error.to_s + " Twitter::Error::InternalServerError"
        return [] if(num_attempts >= 2)
        sleep(sleep_seconds)
        retry
      rescue Twitter::Error::TooManyRequests => error
        puts "RATE LIMITED"
        if num_attempts % 3 == 0
          sleep(error.rate_limit.reset_in)
          retry
        else
          current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
          authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                    :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                    :oauth_token => current_user['twitter_token'],
                    :oauth_token_secret => current_user['twitter_secret'],
                    :api_user => current_user.screen_name}
          $client = Twitter::Client.new(authdata)
          retry
        end
      rescue Twitter::Error::NotFound => error
        puts "Twitter::Error:NotFound -- retrying"
        puts error
        #return nil after second attempt
        return [] if(num_attempts >= 2)
        sleep(sleep_seconds)
        retry
      rescue Twitter::Error::Forbidden => error
        puts "Twitter::Error:Forbidden -- retrying"
        puts error
        # previously blocked in this case, however
        # forbidden is more likely to mean that 
        # the queried user has a protected account,
        # rather than that the querying user is blocked
        # so I have commented out this code.
        #puts "blocking #{authdata[:api_user]}"
        #db.block_api_user(authdata)
        return []
      rescue Twitter::Error::ServiceUnavailable => error
        puts "Twitter::Error:ServiceUnavailable -- retrying"
        puts error
        sleep(sleep_seconds)
        retry
      rescue Twitter::Error::BadGateway => error
        puts "Twitter::Error:BadGateway -- retrying"
        puts error
        sleep(sleep_seconds)
        retry
      # it is essential that ClientError is last
      # since it is the parent class for the other errors
      rescue Twitter::Error::ClientError => error
        puts error.to_s + " Twitter::Error::ClientError"
        return [] if(num_attempts >= 2)
        sleep(sleep_seconds)
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
      $client = self.catch_rate_limit(authdata, db){
        Twitter::Client.new(authdata)
      }
      
      #fetch 100 UUIDs of possibly stale profile images from the accounts table
      uuids = db.fetch_100_stale_profile_image_accounts_and_flag
      users = self.catch_rate_limit(authdata, db){
       $client.users(uuids)
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

class ArchiveTweetsFromUserAccounts
  include CatchTwitterRateLimit
  @queue = "followbias_jobs_#{Rails.env}".to_sym

  # code adapted from iron_ebooks, originally by Jacob Harris
  # https://github.com/natematias/iron_ebooks
  def self.file_exists? account, dir
    File.exist?(File.join(dir, "#{account}.json"))
  end

  def self.perform task
    puts task

    account = task["account"] #TODO JNM

    dir = task["dir"]
    if self.file_exists?(account, dir)
      puts "file exists"
      return
    end
    db = DataObject.new
    current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
    authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                :oauth_token => current_user['twitter_token'],
                  :oauth_token_secret => current_user['twitter_secret'],
                  :api_user => current_user.screen_name}
    $client = self.catch_rate_limit(authdata, db){
              Twitter::Client.new(authdata)
             }
    puts account
    user_tweets = []
    authdata[:followbias_user] = account #TODO JNM
    print "o"
    tweets = self.catch_rate_limit(authdata, db){$client.user_timeline(account, :count => 200, :trim_user => true, :exclude_replies => false, :include_rts => true, :include_entities=>true)}
    print "."
    if(tweets and tweets.size > 0 )
      max_id = tweets.last.id
      user_tweets.concat tweets

      17.times do
        print "."
        tweets = []
        tweets = self.catch_rate_limit(authdata, db){
          $client.user_timeline(account, :count => 200, :trim_user => true, :max_id => max_id - 1, :exclude_replies => false, :include_rts => true, :include_entities=>true)
        }
        puts "MAX_ID #{max_id} TWEETS: #{user_tweets.length}"
        break if tweets.last.nil?
        max_id = tweets.last.id
        user_tweets.concat tweets
      end
    end
    File.open(File.join(dir, "#{account}.json"), "w") do |f|
      f.puts user_tweets.to_json
    end
  end
end

class ProcessUserFriends
  include CatchTwitterRateLimit
  #@queue = "followbias_#{Rails.env}".to_sym
  @queue = "fetchfriends#{Rails.env}".to_sym

  def self.perform(authdata)
    db = DataObject.new


    # symbolise keys
    authdata.keys.each do |key|
      authdata[(key.to_sym rescue key) || key] = authdata.delete(key)
    end

    puts "connecting to Twitter API"
    $client = self.catch_rate_limit(authdata, db){
      Twitter::Client.new(authdata)
    }

    if(!authdata[:followbias_user].nil?)
      # handle screen name and ID cases
      # by converting user_id to an integer only if it is one
      user_identifier = Integer(authdata[:followbias_user]) rescue false
      if(user_identifier == false)
        user_identifier = authdata[:followbias_user]
      end

      followbias_user = self.catch_rate_limit(authdata, db){
        $client.user(user_identifier)
      }
      if(!db.user_exists? followbias_user.screen_name)
        db.create_user(followbias_user)
      end
    else
      followbias_user = $client.user
    end


    if db.too_soon followbias_user
      puts "TOO SOON"
      return nil
    end

    cursor = -1
    friendship_ids = []
    puts "fetching friendship ids"
    #puts followbias_user.attrs[:id]

    friends_count = followbias_user.friends_count
    if friends_count > MAX_FRIENDS
      puts "#{friends_count} > MAX_FRIENDS(#{MAX_FRIENDS})"
      return nil
    end


    error_count = 0;
    while cursor != 0 do
      friendships = self.catch_rate_limit(authdata, db) {
        $client.friend_ids(followbias_user.attrs[:id], {:cursor=>cursor})
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
    new_follows =follows  db.strip_redundant_accounts follows
    puts "fetching friendship data for #{follows.size} accounts"

    all_follow_data = []

    # TODO: POSSIBLE OPPORTUNITY TO BREAK OUT A PARALLEL TASK
    puts "fetching friendship data"
    while more
      if head + 100 > new_follows.size
        more = false
      end

      break if new_follows.size == 0

      puts "new follows: #{new_follows[head, 100]}"

      all_follow_data.concat self.catch_rate_limit(authdata, db){
        $client.users(new_follows[head, 100], :method => :post)
      }
      head += 100
      print "."
    end
    print " #{all_follow_data.size}"

    #all_follow_data.each do |account|
    #  puts "#{account.name}: @#{account.screen_name}: #{account.url}"
    #end

   ### ==>
   db.save_friends(followbias_user.attrs[:id], all_follow_data, follows, followbias_user)
   puts "FRIENDS SAVED"
  end

end
