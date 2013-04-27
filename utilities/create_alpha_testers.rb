require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'

whitelist = CSV.read(ARGV[0])


# "test"  treatment group
# "ctl"   control group
# "alpha" alpha testers
# "new"   non whitelisted users

# STEP ONE: ADD ALL PARTICIPANTS TO THE TREATMENT GROUP
whitelist.each do |row|
  screen_name = row[0]
  user = User.find_by_screen_name(screen_name)
  next if !user
  if(user.treatment=="test" or user.treatment=="ctl")
    puts "ERROR: #{screen_name} is a test participant. Skipping"
    next
  end
  user.treatment = "alpha"
  user.save
end

alpha = User.where({:treatment=>"alpha"})


puts "GENERATED ALPHA TESTERS"
puts "  participants:  #{alpha.size}"
