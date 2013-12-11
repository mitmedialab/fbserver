require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

if User.find_by_screen_name("FollowBias System").nil?
  user = User.create({:screen_name=>"FollowBias System", :uid=> "-1"})
  user.treatment="system"
  user.save!
end

