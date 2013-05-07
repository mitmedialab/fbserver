# -*- encoding : utf-8 -*-
require 'json'
class User < ActiveRecord::Base
  attr_accessible :name, :provider, :uid, :screen_name, :twitter_token, :twitter_secret
  has_many :friendsrecords
  has_many :account_gender_judgments
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.screen_name = auth["info"]["nickname"]
      user.twitter_token =  auth['credentials']['token']
      user.twitter_secret = auth['credentials']['secret']
      puts auth['credentials']
    end
  end

  def all_friends
    unless self.friendsrecords.last.nil?
      Account.where("uuid IN (?)", JSON.parse(self.friendsrecords.last.friends))
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

  def all_friends_paged(limit,offset)
    unless self.friendsrecords.last.nil?
      #sort by occurrence of ' ' to prioritise likely miscategorised accounts
      Account.where("uuid IN (?)", JSON.parse(self.friendsrecords.last.friends)).order("INSTR(name,' ') ASC").limit(limit).offset(offset)

      # when sorting, prioritize items for which there is no custom gender
      # BAD IDEA, since it causes gaps in the paging
      # ALAS
      #Account.find_by_sql("select a.*, g.gender as g_gender from accounts a LEFT JOIN account_gender_judgments g on (a.id = g.account_id) LEFT OUTER JOIN account_gender_judgments g2 ON (a.id = g2.account_id AND (g.created_at < g2.created_at OR g.created_at = g2.created_at AND g.id < g2.id)) WHERE g2.id IS NULL AND uuid in (#{self.friendsrecords.last.friends[1..-2]}) ORDER BY g_gender ASC, INSTR(name,' ') DESC  LIMIT #{offset.to_i},#{limit.to_i}")
    else
      []
    end
  end

  def followbias_at_time datetime
    # get the report from that time
    # if you want to calibrate it to specific friendrecords
    # run this repeatedly for the dates of those friendrecords
    friendrecord = self.friendsrecords.where("created_at <= '#{datetime.to_s(:db)}'").order("created_at ASC").last
    return [] if friendrecord.nil?
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    accounts = Account.where("uuid IN (?)", JSON.parse(friendrecord.friends))

    accounts.each do |account|
      gender = account.gender_at_time datetime
      score[:male] += 1 if gender=="Male"
      score[:female] += 1 if gender == "Female"
      score[:total_following] += 1
    end
    score[:unknown] = score[:total_following] - score[:male] - score[:female]
    score[:account] = self.screen_name
    score
  end

  def followbias
    return nil if self.friendsrecords.order("created_at ASC").last.nil? or self.friendsrecords.order("created_at ASC").last.friends == ""
    score = {:male=>0, :female=>0, :unknown=>0, :total_following=>0}
    self.all_friends.each do |account|
      gender = account.gender
      score[:male] += 1 if gender=="Male"
      score[:female] += 1 if gender == "Female"
      score[:total_following] += 1
    end
    score[:unknown] = score[:total_following] - score[:male] - score[:female]
    score[:account] = self.screen_name
    score
  end
end
