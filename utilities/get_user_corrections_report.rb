require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

correction_users = []
all_users = User.where("treatment='test'")
total_user_corrections = 0

puts "fetching corrections user"

all_users.each do |user|
  if user.account_gender_judgments.size > 0
    correction_users << user 
  end
  total_user_corrections += user.account_gender_judgments.size
end

puts "===== Corrections ====="
puts "total corrections     : #{total_user_corrections}"
puts "total test users      : #{all_users.size}"
puts "total correction users: #{correction_users.size}"

puts "======================="
puts "friends_at_last_correction,correction_duration_seconds,corrections"
correction_users.each do |user|
  gender_judgments = user.account_gender_judgments.order("created_at ASC")
  friends = JSON.parse(user.friendsrecords.where("created_at <= '#{gender_judgments.last.created_at.to_s(:db)}'").order("created_at ASC").last.friends)
  duration = gender_judgments.last.created_at.to_time - gender_judgments.first.created_at.to_time
  puts "#{friends.size},#{duration},#{gender_judgments.size}"
end
