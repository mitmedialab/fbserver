require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
ng = NameGender.new

whitelist = CSV.read(ARGV[0])
screen_names = []
whitelist.each do |row|
  screen_names << '"' + row[0] + '"'
end

puts "screen_name,name,gender,female_follow, male_follow, unknown_follow, total_follow, total_followers"

screen_names.each do |screen_name|
  user = User.where("screen_name =#{screen_name}").first
  if user.nil?
    next
  end
  fb = user.followbias
  followers_count = nil
  begin
    stats = user.userstats
  rescue JSON::ParserError => error
    stats = nil
  end
  if(!stats.nil? and stats.has_key? 'followers_count')
    followers_count = stats['followers_count']
  end
  puts [user.screen_name.downcase, user.name, ng.process(user.name)[:result], fb[:female], fb[:male], fb[:unknown], fb[:total_following], followers_count ].join(",") if fb
end
