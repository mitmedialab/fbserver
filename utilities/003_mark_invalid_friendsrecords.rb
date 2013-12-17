require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

#run before migrate_cache_all_followbias_records.rb

Friendsrecord.all.each do |fr|
  if(fr.friends[-1]!="]" and !fr.incomplete)
    puts fr.user.screen_name
    fr.incomplete=true
    fr.save
  end
end
