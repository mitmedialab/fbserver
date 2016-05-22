require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'csv'
require 'json'

#test_users = User.where("treatment='04.2013.test'")
#ctl_users = User.where("treatment='04.2013.ctl' or treatment='04.2013.ctl1'")

test_names = BloomFilter.new size: 10_000_000, error_rate: 0.00001
ctl_names = BloomFilter.new size: 10000, error_rate: 0.00001


def all_friends_for_record record
    table_name = "all_friends_temp"
    ActiveRecord::Base.connection.execute "DROP TEMPORARY TABLE IF EXISTS #{table_name};"
    ActiveRecord::Base.connection.execute "CREATE TEMPORARY TABLE #{table_name}(t_uuid BIGINT);"
    ActiveRecord::Base.connection.execute "INSERT INTO #{table_name}(t_uuid) values(#{record.friends.gsub(",", "),(")[1..-2]});"
    return Account.find_by_sql("SELECT accounts.* from #{table_name} JOIN accounts ON accounts.uuid=t_uuid;")
end

users = []

CSV.foreach("/mnt/data/corrections.5.22.2016/first_deployment_results_merged_with_survey_05_21_2016.csv", :headers=>true) do |row|
  user = User.find_by_id(row['user.id'])
  #puts user.screen_name + " : " + row['user.screen_name']
  if row['user.group'] == "test" or row['user.group'] == "test- incomplete"
    test_names.insert row['user.screen_name']
  elsif row['user.group'] == 'ctl' or row['user.group'] == 'ctl1' or row['user.group'] == 'ctl1- incomplete'
    ctl_names.insert row['user.screen_name']
  end
  users << user
end

all_user_csv_array = []

CSV.foreach("/mnt/data/corrections.5.22.2016/first_deployment_results_merged_with_survey_05_21_2016.csv", :headers=>true) do |row|
  user = User.find_by_id(row['user.id'])
  friend_record = user.friendsrecords.where("created_at = '#{row['lfb.date']}'").first

  if friend_record.nil?
    puts "No record for #{user.screen_name}"
  end

  test_exposure = 0
  #ctl_spillover = 0
  all_friends_for_record(friend_record).each do |friend|
    test_exposure += 1 if test_names.include? friend.screen_name
  end
  row['test.exposure'] = test_exposure
  all_user_csv_array << row.to_hash
end

CSV.open("/mnt/data/corrections.5.22.2016/first_deployment_results_merged_with_survey_spillover_05_22_2016.csv", "wb") do |csv|
  csv << all_user_csv_array.first.keys
  all_user_csv_array.each do |hash|
    csv << hash.values
  end
end
