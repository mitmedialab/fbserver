require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'twitter'
require 'csv'
require 'resque'
require 'resque-lock-timeout'

all_accounts = []
all_users = []

User.where("treatment='pop'").each do |user|
  all_users << user.uid
end

File.open(ARGV[0], "w") do |file|
  file.puts("digraph journalists{\n")
  User.where("treatment='pop'").each do |user|
    puts user.uid
    friends = user.all_friends
    account = Account.find_by_uuid(user.uid)

    num_attempts = 0
    stats = nil
    begin
      stats = user.userstats
    rescue
      num_attempts += 1
      last = user.friendsrecords.last
      last.twitter_json = last.twitter_json[1..-2].gsub("\\", "")
      if num_attempts <=3
        retry
      end
    end
 
    stats = {"followers_count" => 0} if stats.nil? 
    followers_count = stats['followers_count']

    file.puts "  #{user.uid} [type=user, gender=#{account.gender}, followers=#{followers_count}, name='#{user.name}', screen_name='#{user.screen_name}'];"

    friends.each do |friend|
      if !all_users.include?(friend.uuid) and !all_accounts.include?(friend.uuid)
        file.puts "  #{user.uid} [type=account, gender=#{friend.gender}, name='#{friend.name}', screen_name='#{friend.screen_name}'];" 
        all_accounts << friend.uuid
      end
      file.puts "  #{user.uid} -> #{friend.uuid};"
    end
  end
  file.puts "}"
end
