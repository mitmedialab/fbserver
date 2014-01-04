require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'

whitelist = CSV.read(ARGV[0])


# "test"  treatment group
# "ctl"   control group
# "alpha" alpha testers
# "new"   newly added users, via the site or whitelist
# "pop"   population group

# STEP ONE: ADD ALL PARTICIPANTS TO THE TREATMENT GROUP
whitelist.each do |row|
  screen_name = row[0]
  user = User.find_by_screen_name(screen_name)
  next if !user
  if(user.treatment!="new")
    puts "ERROR: #{screen_name} is a test participant. Skipping"
    next
  end
  print "."
  user.treatment = ARGV[1]
  user.save
end

pop = User.where({:treatment=>ARGV[1]})


puts "set #{ARGV[1]} group"
puts "  participants:  #{pop.size}"
