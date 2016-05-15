require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'simple_stats'

gender = NameGender.new

## TO USE THIS, PROVIDE AN OUTPUT FILE IN ARGV AS IN
# get_acocunt_gender_for_segment.rb OUTFILE

all_users = []
CSV.open(ARGV[0], "wb") do |csv|
  csv << ["name","twitterlink","gender","corrected_gender"]
	Segment.where(:name=>"RegionalJournalists", :subsegment=>"all").first.users.each do |user|
    csv << [user.name.gsub(",",""), "https://twitter.com/#{user.screen_name}", gender.process(user.name)[:result]]
	end
end

