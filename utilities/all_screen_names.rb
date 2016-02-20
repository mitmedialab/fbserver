require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

User.all.each do |user|
  begin
    puts user.screen_name
  rescue Exception =>e
  end
end

