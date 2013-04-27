require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'twitter'
require 'csv'

prng = Random.new(1357911)

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
  user.treatment = "test"
  user.save
end

participants = User.where({:treatment=>"test"})

control_size = (participants.size.to_f * 0.12).round

ctl_count = 0
while ctl_count < control_size
  i = prng.rand(participants.size) 
  if(participants[i].treatment!="ctl")
    participants[i].treatment="ctl"
    participants[i].save
    ctl_count += 1
  end
end

puts "GENERATED CONTROL GROUP"
puts "  participants:  #{participants.size}"
puts "  control group: #{ctl_count}"
