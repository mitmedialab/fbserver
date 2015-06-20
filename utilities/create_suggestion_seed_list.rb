require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'json'

# CREATE A SEED LIST OF ALL ACCOUNTS FOLLOWED BY
# TEST SUBJECTS, WITH DUPLICATES

#ARGUMENTS: ruby create_suggestion_seed_list.rb <number> 

RANDOM_SEED = 12192013 #deterministic, for duplication
rand = Random.new(RANDOM_SEED)

puts "LOADING ACCOUNTS"
File.open("seed_list_unsorted.tmp", "w+") do |outfile|
  #use the test subjects for the full follow seed
  User.where("treatment='test' OR treatment='ctl'").each do |u|
    begin
      outfile.puts JSON.parse(u.friendrecords.where("incomplete IS NOT TRUE").last.friends).join("\n")
      print "."
    rescue
      print "x"
    end
  end
end

puts "SORTING"
puts `sort seed_list_unsorted.tmp > seed_list_sorted.tmp`

suggestions = []
puts "CALCULATING ACCOUNTS WITH MORE THAN ONE USER FOLLOWING"
File.open("seed_list_sorted.tmp", "r") do |file|
  current_buffer_line = ""
  prev_line =""
  file.each do |line|
    line = line.strip

    if(prev_line == line and line != current_buffer_line)
      suggestions << line
      current_buffer_line = line 
    end
    prev_line = line
  end
end

`rm seed_list_sorted.tmp seed_list_unsorted.tmp`
#File.open(ARGV[1], "w+") do |outfile|

#make the suggestions from the system user

user = User.find_by_screen_name("FollowBias System")
suggestion_size = suggestions.size
limit = ARGV[0].to_i - 1
(0..limit).each do |i|
  index = rand.rand(suggestion_size)
  user.suggest_account(Account.find_by_uuid(suggestions[index]))
  suggestions.delete(index)
  suggestion_size -=1
end
