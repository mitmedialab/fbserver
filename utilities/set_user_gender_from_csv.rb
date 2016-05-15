require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'csv'

system = User.find_by_uid(-1)

CSV.foreach(ARGV[0], :headers=>true) do |row|
  row = row.to_hash
  screen_name = row['twitterlink'].gsub(/.*?twitter.com\//, "")
  name = row['name']
  corrected_sex = row['corrected_sex']
  if(!corrected_sex.nil? and corrected_sex.strip.size>0)
    corrected_sex.strip!
    user = User.where(:name=>name, :screen_name=>screen_name)
    if(user and user.first)
      user.first.gender = corrected_sex
      user.first.save
      a = Account.find_by_uuid(user.first.uid)
      if(a)
        a.correct_gender(system, corrected_sex)
        print "a"
      end
      print "x"
    else
      print " ERROR: " + name + " "
    end
      STDOUT.flush
  end
end
