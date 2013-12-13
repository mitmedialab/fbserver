require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

# this should only be run once on a given server
# and only to migrate to the FollowBias System user 
# approach to storing account gender judgments

# this script may take up to an hour or longer

# NOTE: you can reverse this by deleting all account_gender_judgments with system_user_id
# NOTE: after this, you need to run migrate_judgment_data_to_cache_in_accounts.rb

require 'mysql2'

page_size = 1000


db = Mysql2::Client.new(:host => "localhost", :username => "fbserver", :database=>"fbserver_#{Rails.env}")

system_user_id = db.query("select id from users where screen_name='Followbias System'").collect{|a|a["id"]}[0].to_i

counter = 0
total = db.query("select count(*) as c from accounts;").collect{|a|a["c"]}[0].to_i
puts "Total Accounts: #{total}"

while counter <= total
  query ="INSERT INTO account_gender_judgments(account_id, user_id, gender, created_at) VALUES"
  
  db.query("select * from accounts LIMIT #{counter},#{page_size};").each do |row|
    query+= "\n(#{row['id']}, #{system_user_id}, '#{row['gender']}', '#{row['created_at']}'),"
  end
  query[-1]=";"
  #puts query
  db.query(query)

  print "."
  counter += page_size
end

#puts "Total: #{total}"
#puts "Counter: #{counter}"
