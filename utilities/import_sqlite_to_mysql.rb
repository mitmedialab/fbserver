require '../config/environment'
require 'twitter'
require 'sqlite3'
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')

count = 0;
columns = nil
db = SQLite3::Database.new(File.join(File.dirname(__FILE__), "../db/development.sqlite3"))
db.execute2( "select * from accounts;" ) do |row|
  if columns.nil?
    columns = row
  else
    row = Hash[columns.zip(row)]
    unless Account.find_by_uuid row["uuid"]
      Account.create(:uuid=>row["uuid"], :screen_name=>row["screen_name"], :name=>row["name"], :profile_image_url=>row["profile_image_url"], :gender=>row["gender"])
      count += 1
      if(count % 100 == 0)
        print "O"
      else
        print "."
      end
    end
  end
end
