require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')

all_accounts = {}

system_user = User.find_by_screen_name "FollowBias System"

User.where("(treatment='test' OR treatment='ctl') AND twitter_token IS NOT NULL and survey_complete=true ").each do |user|
  lfb = user.friendsrecords.order(:created_at).last
  print "."
  STDOUT.flush
  Account.where("uuid IN (?)", JSON.parse(lfb.friends)).each do |account|
    if(all_accounts.include? account.id)
      all_accounts[account.id][:count]+=1
    else
      obj = {
        :fullname => (!account.name.index(" ").nil?),
        :corrected => (account.account_gender_judgments.size == 0 || account.account_gender_judgments.last.user_id !=system_user.id),
        :gender => account.gender[0],
        :count => 1
      }
      all_accounts[account.id] = obj
    end
  end
end

puts
puts "id,count,gender,corrected,fullname"
all_accounts.each do|id, obj|
  puts "#{id},#{obj[:count]},#{obj[:gender]},#{obj[:corrected]  ? 1 : 0},#{obj[:fullname] ? 1 : 0}"
end
