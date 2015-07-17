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

db = Mysql2::Client.new(:host => "localhost", :username => "fbserver", :database=>"fbserver_#{Rails.env}")

#account_ids = Hash.new { |h, k| h[k] = [] }
#account_sns = Hash.new { |h, k| h[k] = [] }
#bothkey = Hash.new { |h, k| h[k] = [] } 

#subquery = "SELECT DISTINCT(account_id) from account_gender_judgments WHERE user_id!=1024"
Account.find_by_sql("SELECT accounts.* from accounts JOIN account_gender_judgments as agj ON accounts.id = agj.account_id WHERE agj.user_id!=1024;").each do |account|
  #account_ids[account.uuid] << account
  #account_sns[account.screen_name] << account
  #bothkey[account.screen_name + account.uuid.to_s] << account
end


class UpdateUUIDs
  include CatchTwitterRateLimit
# NOW UPDATE THE UUIDS
  def self.perform
    @db = DataObject.new
    @current_user = User.order("RAND()").where("twitter_secret IS NOT NULL AND failed IS NOT TRUE").first
    @authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                :oauth_token => @current_user['twitter_token'],
                :oauth_token_secret => @current_user['twitter_secret'],
                :api_user => @current_user.screen_name}
    $client = self.catch_rate_limit(@authdata, @db){
      Twitter::Client.new(@authdata)
    }
    Account.find_by_sql("SELECT accounts.* from accounts JOIN account_gender_judgments as agj ON accounts.id = agj.account_id WHERE agj.user_id!=1024;").each do |account|
       #first, try to access by uuid
       t_account = self.catch_rate_limit(@authdata, @db, 2){
         $client.user(account.uuid)
       }
       #next, try to access by screen name
       if(t_account.nil? or t_account.kind_of?(Array))
         t_account = self.catch_rate_limit(@authdata, @db, 2){
           $client.user(account.screen_name)
         }
         #if you retrieved the account, assume the uid is wrong 
         #and save the new uid
         if(!t_account.nil? and !t_account.kind_of?(Array))
           self.update_account_details(account,t_account)
           print "o"
         end
       else
         print "."
       end
    end
  end

  def self.update_account_details account, t_account
    account.uuid = t_account.id
    account.screen_name = t_account.screen_name
    account.name = t_account.name
    account.profile_image_url = t_account.profile_image_url
    account.profile_image_updated_at = Time.now
    account.save!
  end
  
end

UpdateUUIDs.perform
