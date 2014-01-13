require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')

puts "user_id, gender,treatment,followbias_date,fb male,fb female,fb unknown"

User.where("(treatment='ctl' OR treatment='test' ) AND twitter_token IS NOT NULL").each do |user|
  # verify that they took the survey and returned to the site
  gender = "Unknown"
  a = Account.find_by_uuid(user.uid.to_i)
  gender = a.gender if a

  user.followbias_records.each do |ffb|
    puts [user.id, gender, user.treatment, 
          ffb.created_at, ffb.male, ffb.female, ffb.unknown].join(",")
  end
end

