require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require 'simple_stats'

## TO USE THIS, PROVIDE AN OUTPUT FILE IN ARGV AS IN
# generate_followbias_activity_table.rb INDIR OUTFILE

all_users = []
User.where("treatment='pop'").each do |user|
  all_users << user.uid.to_i
end

pop_users = []

gender = NameGender.new

#filecounter = 0

Dir.glob(ARGV[0] + '*.json', File::FNM_DOTMATCH) do |f|
  #puts f
  first = 1
  userhash = {}

  #break if filecounter >= 20
  #filecounter += 1
 
  # set default value of the hash
  mentioned_people = Hash.new{ |h, k| h[k] = {
    "name"=>nil,
    "id_str"=>nil,
    "screen_name"=> nil,
    "unique_tweets" => 0
  }}

  unique_mentions_per_tweet = []

  tweet_dates = []
  
  shouldbreak = 0
  JSON.load(File.open(f, "r").read).each do |tweet|
    #### FIRST TWEET TO GET USER ####
    if(first==1)
      user = tweet['user']
      user_id = user['id_str'].to_i
    
      fbuser = User.find_by_uid(user_id)
      if fbuser.nil? 
        shouldbreak = 1
        break
      end
      fbrecord = fbuser.followbias
      if fbrecord.nil?
        shouldbreak = 1
        break
      end

      #if(all_users.include? user_id)
      userhash = {
        "uid" => user_id,
        "gender" => gender.process(fbuser.name)[:result],
        "tweets_mentioning_people" => (tweet['entities']['user_mentions'].size > 0) ? 1 : 0,
        "unique_mentions_per_tweet" => nil
      }.merge(fbrecord)
      #else
      #  break
      #end
      #puts userhash
    end
    first = 0

    break if shouldbreak==1

    tweet_dates << DateTime.parse(tweet['created_at'])

    #### NOW PROCESS THE TWEETS TO MAKE A LIST OF WHO THEY MENTION ####
    tweet['entities']['user_mentions'].each do |mention|
      mention_id = mention['id_str']
      mentioned_people[mention_id].merge!(mention)
      mentioned_people[mention_id]['unique_tweets'] += 1
      mentioned_people[mention_id]["name_sex"] = gender.process(mention['name'])[:result]
    end
    
    unique_mentions_per_tweet << tweet['entities']['user_mentions'].size
  end
  
  ## CALCULATE TWEETS PER MONTH
  if(tweet_dates.size>0)
    tweet_dates.sort!{|a,b| a <=> b}
    lastmonth = tweet_dates[-1] - 1.month
    userhash['total_last_month_tweets'] = tweet_dates.select{|x|x >= lastmonth}.size()
  else
    userhash['total_last_month_tweets'] = 0
  end

  userhash['total_unique_mentions'] = mentioned_people.size
  #puts "\n\n\n=========="
  #puts mentioned_people.values.collect{|x|x['unique_tweets']}
  userhash['total_mentions'] = mentioned_people.values.collect{|x|x['unique_tweets']}.sum
  ['Female','Male','Unknown'].each do |sex|
    userhash["total_unique_#{sex}_mentions"] = mentioned_people.values.collect{|x|x['name_sex']==sex ? 1: 0 }.sum
    userhash["total_#{sex}_mentions"] = mentioned_people.values.collect{|x| x['name_sex']==sex ? x['unique_tweets']: 0 }.sum
  end

  userhash['unique_mentions_per_tweet'] = unique_mentions_per_tweet.mean()

  ## THIS IS A TERRIBLE HACK, BUT SIGH
  if(userhash.keys.include? "uid")
    puts userhash
    pop_users << userhash
  end
end

CSV.open(ARGV[1], "wb") do |csv|
  csv << pop_users.first.keys # adds the attributes name on the first line
  pop_users.each do |hash|
    csv << hash.values
  end
end

