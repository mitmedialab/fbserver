require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

# this should only be run once on a given server
# and only to migrate to the FollowBias System user 
# approach to storing account gender judgments


system_user = User.find_by_screen_name("FollowBias System")

counter = 0
total = Account.count
tenpercents = total / 10
puts "Total Accounts: #{total}"

Account.find_each do |account|
  counter +=1
  print "." if (counter % 100) == 0
  puts "" if (counter % tenpercents) == 0
  system_user.account_gender_judgments.create({:account_id => account.id, :gender=> account.gender, :created_at=>account.created_at})
end
