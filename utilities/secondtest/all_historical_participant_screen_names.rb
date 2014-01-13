require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')


User.where("treatment='04.2013.test' AND twitter_token IS NOT NULL").each do |user|
  puts [user.screen_name,user.name].join(",")
end
