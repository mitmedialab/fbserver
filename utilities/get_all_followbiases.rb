require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

test_users = User.where("treatment='test'")
ctl_users = User.where("treatment='ctl' or treatment='ctl1'")

def print_row user
  begin
		initial = user.followbias_at_time(user.friendsrecords.order("created_at ASC").first.created_at + 5.minutes, false)
		login = user.followbias_at_time(user.updated_at, false)
		time_to_login = user.updated_at.to_time - user.created_at.to_time
		latest = user.followbias_at_time(Time.now(), false)
		time_to_latest = user.friendsrecords.order("created_at ASC").last.created_at.to_time - user.created_at.to_time
    puts "#{initial[:total_following]},#{login[:total_following]},#{latest[:total_following]},#{initial[:female]},#{initial[:male]},#{initial[:unknown]},#{login[:female]},#{login[:male]},#{login[:unknown]},#{latest[:female]},#{latest[:male]},#{latest[:unknown]},#{time_to_login},#{time_to_latest}"
  rescue
   puts "ERROR with #{initial}"
   #puts initial
   #puts login
   #puts latest
  end
end

puts "==== Treatment Group (absolute) ===="
puts "friends_initial,friends_login,friends_last,female_initial,male_initial,unknown_initial,female_login,male_login,unknown_login,female_last,male_last,unknown_last,time_to_login,time_to_last_friends"
test_users.each do |user|
  print_row user
end

puts ""
puts "==== Control Group (absolute) ===="
puts "friends_initial,friends_login,friends_last,female_initial,male_initial,unknown_initial,female_login,male_login,unknown_login,female_last,male_last,unknown_last,time_to_login,time_to_last_friends"
ctl_users.each do |user|
  print_row user
end
