# -*- encoding : utf-8 -*-
require 'json'
class User < ActiveRecord::Base
  attr_accessible :name, :provider, :uid, :screen_name, :twitter_token, :twitter_secret
  has_many :friendsrecords
  has_many :account_gender_judgments
  has_many :activity_logs
  has_many :followbias_records

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.screen_name = auth["info"]["nickname"]
      user.twitter_token =  auth['credentials']['token']
      user.twitter_secret = auth['credentials']['secret']
    end
  end

  #TODO: write a test for this method
  def suggests_account? account
    self.all_suggested_accounts.include? account.uuid.to_i
  end

  def suggest_account account
    uuid = account.uuid.to_i
    all_suggested = self.all_suggested_accounts

    if !all_suggested.include? uuid  
      all_suggested << uuid
      self.suggested_accounts = all_suggested.to_json
      self.save!
    end

    suggestion = account.get_account_suggestion
    if suggestion.users.nil? or !suggestion.users.include? self.uid.to_i
      suggestion.add_user self
    end
  end

  def all_suggested_accounts
    return [] if self.suggested_accounts.nil?
    JSON.parse(self.suggested_accounts).collect{|i|i.to_i}
  end
 
  def friendrecords
    self.friendsrecords.where("incomplete IS FALSE")
  end

  def receive_random_suggestions count

    results = []
    follow_list = JSON.parse(self.friendrecords.last.friends).collect{|i|i.to_i}

    #fetch a list of all accounts that the user doesn't already follow
    all_suggestions = AccountSuggestion.where("CHAR_LENGTH(suggesters) >2").find_all{|suggestion| !follow_list.include?(suggestion.account.uuid) }

    return all_suggestions.collect{|i|i.account} if all_suggestions.size <= count
    
    result_keys = []
    while(result_keys.size < count )
      n = Random.rand(all_suggestions.size)
      if(!result_keys.include?(n))
        result_keys << n
      end
    end
    
    # return the accounts associated with suggestion results
    result_keys.collect{|i| all_suggestions[i].account}
  end

  def unsuggest_account account
    # remove user from account
    accounts = self.all_suggested_accounts 
    accounts.delete account.uuid.to_i
    self.suggested_accounts = accounts.to_json
    self.save
    #remove suggestion from user
    account.account_suggestion.remove_user self
  end

  #TODO: refactor to allow users to specify a friendsrecord
  #TODO: refactor to allow users to specify a date
  def all_friends
    last = self.friendrecords.last
    unless last.nil? or last.friends==""
      #begin
        Account.where("uuid IN (?)", JSON.parse(last.friends))
      #rescue Exception => e
      #  puts e
        #puts "FRIENDS: #{last.friends}"
        #exit(1)
      #  []
      #end
    else
      []
    end
  end

  def sample_friends
    sz = 2
    friends = []
    counters = {"Male"=>0, "Female" =>0, "Unknown" =>0}
    self.all_friends.each do |f|
      break if counters["Male"] >= sz and counters["Female"] >= sz and counters["Unknown"] >= sz
      if counters[f.gender] < sz
        friends << f
        counters[f.gender] += 1
      end
    end
    friends
  end

  def all_friends_paged(limit,offset, sort="correct")
    last = friendrecords.last
    unless last.nil?
      if(sort =="suggest")
        Account.find_by_sql(["select * from accounts WHERE UUID IN (?) ORDER BY gender ASC LIMIT #{offset.to_i},#{limit.to_i}", JSON.parse(last.friends)])
      else
        #sort by occurrence of ' ' to prioritise likely miscategorised accounts
        Account.where("uuid IN (?)", JSON.parse(last.friends)).order("INSTR(name,' ') ASC").limit(limit).offset(offset)
      end

      # when sorting, prioritize items for which there is no custom gender
      # BAD IDEA, since it causes gaps in the paging
      # ALAS
      #Account.find_by_sql("select a.*, g.gender as g_gender from accounts a LEFT JOIN account_gender_judgments g on (a.id = g.account_id) LEFT OUTER JOIN account_gender_judgments g2 ON (a.id = g2.account_id AND (g.created_at < g2.created_at OR g.created_at = g2.created_at AND g.id < g2.id)) WHERE g2.id IS NULL AND uuid in (#{self.friendsrecords.last.friends[1..-2]}) ORDER BY g_gender ASC, INSTR(name,' ') DESC  LIMIT #{offset.to_i},#{limit.to_i}")
    else
      []
    end
  end

  def followbias_at_time datetime, perception = true
    # get the report from that time
    # if you want to calibrate it to specific friendrecords
    # run this repeatedly for the dates of those friendrecords
    friendrecord = self.friendsrecords.where("created_at <= '#{datetime.to_s(:db)}' AND incomplete IS FALSE").order("created_at ASC").last
    return [] if friendrecord.nil?
    return followbias_for_record friendrecord, perception
    #score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    #accounts = Account.where("uuid IN (?)", JSON.parse(friendrecord.friends))
#
#    accounts.each do |account|
#      gender = account.gender_at_time datetime if perception
#      gender = account.gender unless perception
#      score[:male] += 1 if gender=="Male"
#      score[:female] += 1 if gender == "Female"
#      score[:total_following] += 1
#    end
#    score[:unknown] = score[:total_following] - score[:male] - score[:female]
#    score[:account] = self.screen_name
#    score
  end

  def followbias_for_record friendrecord, perception = true
    return nil if friendrecord.nil?
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    accounts = Account.where("uuid IN (?)", JSON.parse(friendrecord.friends))

    accounts.each do |account|
      gender = account.gender_at_time friendrecord.created_at if perception
      gender = account.gender unless perception
      score[:male] += 1 if gender=="Male"
      score[:female] += 1 if gender == "Female"
      score[:total_following] += 1
    end
    score[:unknown] = score[:total_following] - score[:male] - score[:female]
    score[:account] = self.screen_name
    score

  end

  def followbias
    # note: this will always query the last followbias_record
    # even if there is a more recent friendsrecord that doesn't
    # yet have a corresponding followbias_record
    followbias_record = self.followbias_records.order("created_at ASC").last

    if(followbias_record)

      #self.followbias_records.order("created_at ASC").each do |fr|
      #  puts fr.to_json
      #end

      { :male => followbias_record.male,
        :female => followbias_record.female,
        :unknown => followbias_record.unknown,
        :total_following => followbias_record.total_following,
        :account => self.screen_name }
    else
      self.cache_followbias_record
    end
  end

  # TODO: CREATE NEW METHOD TO CACHE FOR A SPECIFIC FRIENDSRECORD
  def cache_followbias_record
    return nil if self.friendrecords.last.nil? or self.friendsrecords.where("incomplete IS FALSE").order("created_at ASC").last.friends == ""
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    self.all_friends.each do |account|
      gender = account.gender
      score[:male] += 1 if gender=="Male"
      score[:female] += 1 if gender == "Female"
      score[:total_following] += 1
    end
    score[:unknown] = score[:total_following] - score[:male] - score[:female]

    # determine if you should cache this
    fbr = self.followbias_records.last
    save_cache = false
    save_cache = true if(fbr.nil? or 
          ( fbr.male != score[:male] or
            fbr.female != score[:female] or
            fbr.unknown != score[:unknown] or
            fbr.total_following != score[:total_following]))
 
    if(save_cache)
      self.followbias_records.create(score.merge({
        :friendsrecord_id => self.friendrecords.last.id}))
    end

    score[:account] = self.screen_name
    score
  end
end
