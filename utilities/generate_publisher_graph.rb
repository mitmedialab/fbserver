require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'twitter'
require 'csv'
require 'resque'
require 'resque-lock-timeout'
require 'bloom-filter'

all_accounts = BloomFilter.new size: 10_000_000, error_rate: 0.00001
all_users = BloomFilter.new size: 10000, error_rate: 0.00001
journos = BloomFilter.new size: 10000, error_rate: 0.0000001


#all_accounts = []
#all_users = []

whitelist = CSV.read(ARGV[0])
screen_names = []
whitelist.each do |row|
  screen_names << {:screen_name=>row[2] , :publisher=>row[1]}
  journos.insert row[2]
end

i = 0
File.open(ARGV[1], "w") do |file|
  file.puts("digraph journalists{\n")
  screen_names.each do |screen_name|
    user = User.find_by_screen_name(screen_name[:screen_name])
    if(!user.nil?)
			puts "#{i}: #{user.screen_name}"
      i += 1

      if(user.friendsrecords.size==0)
        friends = []
      else
   			friends = user.all_friends
      end
			account = Account.find_by_uuid(user.uid)

			all_users.insert user.uid

			num_attempts = 0
			stats = nil
			begin
				stats = user.userstats
			rescue
				num_attempts += 1
				last = user.friendsrecords.last
				last.twitter_json = last.twitter_json[1..-2].gsub("\\", "")
				if num_attempts <=3
					retry
				end
			end
	 
			stats = {"followers_count" => 0} if stats.nil? 
			followers_count = stats['followers_count']
      if(!account.nil?)
		  	file.puts "  #{user.uid} [type=user, gender=#{account.gender}, followers=#{followers_count}, name='#{user.name.gsub(" ","_").gsub("'","").gsub('"','')}', screen_name='#{user.screen_name.gsub(" ","_").gsub("'","").gsub('"','')}', publisher='#{screen_name[:publisher].gsub(" ","_").gsub("'","").gsub('"','')}'];"

			  friends.each do |friend|
			  	#if !all_users.include?(friend.uuid) and !all_accounts.include?(friend.uuid) and journos.include?(friend.screen_name)
				  	#file.puts "  #{user.uid} [type=account, gender=#{friend.gender}, name='#{friend.name}', screen_name='#{friend.screen_name}'];" 
					#  all_accounts.insert friend.uuid
				  #end
          if(journos.include? friend.screen_name )
  				  file.puts "  #{user.uid} -> #{friend.uuid};"
          end
        end
      end
    end
  end
  file.puts "}"
end
