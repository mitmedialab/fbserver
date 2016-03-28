require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')


whitelist = CSV.read(ARGV[0], headers: true)
org_keys = CSV.read(ARGV[1], headers: true)

segment_name = ARGV[2]
subsegment_name = ARGV[3]

sample = []
whitelist.each do |row|
  sample << {:screen_name=>row["account"] , :publisher=>row["publisher"],:state=>row["state"]}
end

orgs = {}
org_keys.each do |row|
  orgs[row["key"]] = row
end

puts "Total organizations: #{orgs.size}"

##SET UP SAMPLE RELATIONSHIP
segment = Segment.where(:name=>segment_name, :subsegment=>subsegment_name).first
if segment.nil?
  segment = Segment.new(:name=>segment_name, :subsegment=>subsegment_name)
  segment.save
end

puts subsegment_name
puts segment_name
puts segment

sample.each do |sampleuser|
  user = User.where(:screen_name => sampleuser[:screen_name]).first
  if user.nil?
    print "COULD NOT FIND #{sampleuser[:screen_name]}"
  end
  publisher = orgs[sampleuser[:publisher]]

  puts 
  puts "==="
  puts "User Information"
  puts user
  puts sampleuser
  puts "Publisher Information"
  puts publisher
  puts sampleuser[:publisher]
  puts "==="

  ## IF THE ORG IS NOT FOUND IN THE ORGFILE
  if publisher.nil? or publisher['org'].size == 0
    puts "Couldn't find the org"
    puts sampleuser[:publisher]
    puts orgs[sampleuser[:publisher]]
    puts "---"
  end

  # IF THE ORG IS IN THE DATABASE, FETCH IT. OTHERWISE CREATE IT
  org = Organization.where(:name=>publisher['org'], :state=>publisher['state']).first
  if org.nil?
    org = Organization.new(:name=>publisher['org'], :state=>publisher['state'], 
												   :city=>publisher['city'])
    org.save
  end

  if !(user.organizations.include? org)
    user.organizations << org
  end

  ## SET UP THE SEGMENT RELATIONSHIP
  if !(user.segments.include? segment)
    user.segments << segment
  end

  user.save
end
