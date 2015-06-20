require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')

User.where("(treatment='test' OR treatment='ctl') AND twitter_token IS NOT NULL and survey_complete=true ").each do |user|
  puts user.screen_name
end
