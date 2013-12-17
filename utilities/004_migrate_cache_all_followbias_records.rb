require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')


User.all.each do |user|
  if(user.followbias_records.count == 0 or
     user.followbias_records.order("created_at ASC").last.created_at <= 1.day.ago)
    print "."
    user.cache_followbias_record
  else
    print "x"
  end
end
