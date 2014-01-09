require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
ng = NameGender.new


puts "screen_name,name,gender,female_follow, male_follow, unknown_follow, total_follow"
User.where("treatment='pop'").find_each do |user|
  fb = user.followbias
  puts [user.screen_name.downcase, user.name, ng.process(user.name)[:result], fb[:female], fb[:male], fb[:unknown], fb[:total_following] ].join(",") if fb
end
