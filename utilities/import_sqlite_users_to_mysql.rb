require '../config/environment'
require 'twitter'
require 'sqlite3'
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')

count = 0;
columns = nil
db = SQLite3::Database.new(File.join(File.dirname(__FILE__), "../db/development.sqlite3"))
db.execute2( "select * from users;" ) do |row|
  if columns.nil?
    columns = row
  else
    row = Hash[columns.zip(row)]
    unless User.find_by_uid row["uid"]
      User.create(:provider=>row["provider"], :uid=>row["uid"], :screen_name=>row["screen_name"], :twitter_token=>row["twitter_token"], :twitter_secret=>row["twitter_secret"])
      count += 1
      if(count % 100 == 0)
        print "O"
      else
        print "."
      end
    end
  end
end
