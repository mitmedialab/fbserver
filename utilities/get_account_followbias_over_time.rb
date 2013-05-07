require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

def puts_followbias user, time, followbias, extra=nil
  female_pct = (followbias[:female].to_f / followbias[:total_following].to_f).round(2)
  male_pct = (followbias[:male].to_f / followbias[:total_following].to_f).round(2)

  print "#{user.screen_name},#{female_pct},#{male_pct},#{followbias[:male]},#{followbias[:female]},#{followbias[:unknown]},#{followbias[:total_following]},#{time}"
  print ", #{extra}" if !extra.nil?
  print "\n"
end

user = User.find_by_screen_name(ARGV[0])

last_correction = AccountGenderJudgment.where(:user_id=>user.id).order("created_at ASC").last
last_correction_time = nil
last_correction_time = last_correction.created_at if !last_correction.nil?

puts
puts "              user: #{user.screen_name}"
puts "             group: #{user.treatment}"
puts "         survey at: #{user.updated_at}"
puts "       corrections: #{user.account_gender_judgments.size}"
puts "last correction at: #{last_correction_time}"

puts
puts "MAJOR MOMENTS (ABSOLUTE)"
puts "screen_name,female_pct,male_pct,male,female,unknown,total,datetime, moment"
time = user.friendsrecords.order("created_at ASC").first.created_at
followbias = user.followbias_at_time(time, false)
puts_followbias user, time, followbias, "INITIAL"

time = user.updated_at
followbias = user.followbias_at_time(time, false)
puts_followbias user, time, followbias, "FORM_COMPLETE"

if(last_correction_time)
  time = last_correction.created_at
  followbias = user.followbias_at_time(time, false)
  puts_followbias user, time, followbias, "LAST_CORRECTION"
end

time = user.friendsrecords.order("created_at ASC").last.created_at
followbias = user.followbias_at_time(time, false)
puts_followbias user, time, followbias, "LAST_RECORD"

puts
puts "FULL PERCEPTION HISTORY"

puts "screen_name,female_pct,male_pct,male,female,unknown,total,datetime, moment"
user.friendsrecords.order("created_at ASC").each do |fr|
  followbias = user.followbias_at_time(fr.created_at)
  puts_followbias user, fr.created_at, followbias
end

puts
puts "FULL FOLLOWBIAS HISTORY (ABSOLUTE)"

puts "screen_name,female_pct,male_pct,male,female,unknown,total,datetime, moment"
user.friendsrecords.order("created_at ASC").each do |fr|
  followbias = user.followbias_at_time(fr.created_at, false)
  puts_followbias user, fr.created_at, followbias
end
