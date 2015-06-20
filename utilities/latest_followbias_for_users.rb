require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

puts "screen_name, 3fb.date, 3fb.male, 3fb.female, 3fb.unknown"

whitelist = CSV.read(ARGV[0])
whitelist.each do |row|
  uid = row[0]
  user = User.find_by_uid uid
  begin
    ffb = user.followbias_records.order(:created_at).last
    puts [user.id,user.screen_name, ffb.created_at, ffb.male, ffb.female, ffb.unknown].join(",")
  rescue Exception =>e
  end
end

