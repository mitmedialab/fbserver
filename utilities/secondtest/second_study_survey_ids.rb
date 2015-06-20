require 'digest/sha1'
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')

puts "user.id, user.screen_name,survey_id"

User.where("(treatment='test' OR treatment='ctl') AND twitter_token IS NOT NULL and survey_complete=true ").each do |user|
  puts [user.id, user.screen_name, Digest::SHA1.hexdigest(user.screen_name)].join(",")
end
