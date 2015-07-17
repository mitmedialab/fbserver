require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
ng = NameGender.new


puts "screen_name,name,gender,female_follow, male_follow, unknown_follow, total_follow, total_followers"
User.where("treatment='pop'").find_each do |user|
  fb = user.followbias
  followers_count = nil
  begin
    stats = user.userstats
  rescue JSON::ParserError => error
  end
  if(!stats.nil? and stats.has_key? 'followers_count')
    followers_count = stats['followers_count']
  end
  puts [user.screen_name.downcase, user.name, ng.process(user.name)[:result], fb[:female], fb[:male], fb[:unknown], fb[:total_following], followers_count ].join(",") if fb
end
