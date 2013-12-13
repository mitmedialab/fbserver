require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

# this should only be run once on a given server
# and only to migrate to the FollowBias System user 
# approach to storing account gender judgments

# this script may take over an hour to run

# NOTE: RUN THIS AFTER migrate_auto_data_to_gender_judgments.rb
# NOTE: THIS IS NOT EASILY REVERSIBLE


require 'mysql2'

page_size = 1000


db = Mysql2::Client.new(:host => "localhost", :username => "fbserver", :database=>"fbserver_#{Rails.env}")

system_user_id = db.query("select id from users where screen_name='Followbias System'").collect{|a|a["id"]}[0].to_i

counter = 0

account_ids = db.query("select account_id from account_gender_judgments where user_id!=#{system_user_id} GROUP BY account_id;").collect{|a|a["account_id"]}
puts "Total Accounts: #{account_ids.size}"


account_ids.each do |account_id|
  account = Account.find_by_id(account_id)
  account.gender = account.account_gender_judgments.order("created_at ASC").last.gender
  account.save
  print "."
end
