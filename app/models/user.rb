# -*- encoding : utf-8 -*-
require 'json'
class User < ActiveRecord::Base
  attr_accessible :name, :provider, :uid, :screen_name, :twitter_token, :twitter_secret
  has_many :friendsrecords
  has_many :account_gender_judgments
  has_many :activity_logs
  has_many :followbias_records
  has_and_belongs_to_many :segments
  has_and_belongs_to_many :organizations

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

  #TODO: write a test for this
  def userstats
    last = self.friendrecords.last
    if last.nil? or last.twitter_json.nil?
      return nil
    else
     return JSON.parse(last.twitter_json)
    end
  end

  #TODO: refactor to allow users to specify a friendsrecord
  #TODO: refactor to allow users to specify a date
  def all_friends
    last = self.friendrecords.last
    #accounts = []
    # Note: we avoid parsing the JSON by just counting commas here
    # last.friends <= 3 when there are no friends in the list
    if !last.nil? and (last.friends.count(",") > MAX_FRIENDS or last.friends.size<=3)
      return []
    end

    table_name = "all_friends_temp"
    ActiveRecord::Base.connection.execute "DROP TEMPORARY TABLE IF EXISTS #{table_name};"
    ActiveRecord::Base.connection.execute "CREATE TEMPORARY TABLE #{table_name}(t_uuid BIGINT);"
    ActiveRecord::Base.connection.execute "INSERT INTO #{table_name}(t_uuid) values(#{last.friends.gsub(",", "),(")[1..-2]});"
    return Account.find_by_sql("SELECT accounts.* from #{table_name} JOIN accounts ON accounts.uuid=t_uuid;")
  end

  # this only fetches the gender of accounts
  # used to cache the followbias score
  def all_friends_gender
    last = self.friendrecords.last
    # last.friends <= 3 when there are no friends in the list
    if last.nil? or last.friends.nil? or last.friends.count(",") > MAX_FRIENDS or last.friends.size<=3
      return []
    end
    # return a list of genders associated with accounts
    # TODO: consider a faster option than parsing then rejoining
    # you can probably
    #  1. check for closing braces
    #  2. replace the braces with parens
    #  3. insert it straight into the query
    table_name = "all_friends_gender_temp"
    ActiveRecord::Base.connection.execute "DROP TEMPORARY TABLE IF EXISTS #{table_name};"
    ActiveRecord::Base.connection.execute "CREATE TEMPORARY TABLE #{table_name}(t_uuid BIGINT);"
    ActiveRecord::Base.connection.execute "INSERT INTO #{table_name}(t_uuid) values(#{last.friends.gsub(",", "),(")[1..-2]});"
    return ActiveRecord::Base.connection.exec_query("SELECT accounts.gender FROM #{table_name} JOIN accounts ON accounts.uuid=t_uuid;").rows
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
        Account.find_by_sql("select * from accounts WHERE UUID IN (#{JSON.parse(last.friends).join(",")}) ORDER BY gender ASC LIMIT #{offset.to_i},#{limit.to_i};")
      else
        #sort by occurrence of ' ' to prioritise likely miscategorised accounts
        Account.where("uuid IN (#{JSON.parse(last.friends).join(",")})").order("INSTR(name,' ') ASC").limit(limit).offset(offset)
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


  def all_friends_fb_score
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    genders = self.all_friends_gender
    genders.each do |grow| 
      gender = grow[0]
      score[:male] += 1 if gender=="Male"
      score[:female] += 1 if gender == "Female"
      score[:total_following] += 1
    end 
    score[:unknown] = score[:total_following] - score[:male] - score[:female]
    return score
  end

  # TODO: CREATE NEW METHOD TO CACHE FOR A SPECIFIC FRIENDSRECORD
  def cache_followbias_record
    # CONSIDER REFACTORING OUT THIS LINE
    return nil if self.friendrecords.last.nil? or self.friendsrecords.where("incomplete IS FALSE").order("created_at ASC").last.friends == ""
    score = self.all_friends_fb_score

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

  # FETCH THE FOLLOWBIAS COUNT ASSOCIATED
  # WITH ACCOUNTS FROM THE ORGANIZATION
  # This is used to subtract org followbias
  # from a final followbias score
  def organization_users organization
    org_users = []
    self.organizations.each do |org|
      if(org == organization)
				org.users.each do |user|
					org_users << user.uid
				end
      end
    end 
    return org_users
  end

  def organization_followbias organization
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    org_users = organization_users organization    
    # step two: get a list of all followed_users
    self.all_friends.each do |friend|
      if org_users.include? friend.uuid
        gender = friend.gender
				score[:male] += 1 if gender=="Male"
				score[:female] += 1 if gender == "Female"
				score[:unknown] += 1 if gender == "Unknown"
				score[:total_following] += 1
      end
    end
    return score
  end

  def non_organization_followbias organization
    score = self.followbias
    org_score = self.organization_followbias organization
    org_score.keys.each do |key|
      score[key] -= org_score[key]
    end 
    score
  end

end
