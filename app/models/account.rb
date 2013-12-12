# -*- encoding : utf-8 -*-
class Account < ActiveRecord::Base
  attr_accessible :uuid, :screen_name, :name, :gender, :profile_image_url
  has_one :account_suggestion
  has_many :account_gender_judgments
  def gender
    # now that we're (in principle) caching the latest judgment
    # into this table, there's no need for this query
    #if self.account_gender_judgments.size >  0
    #  return self.account_gender_judgments.order("created_at ASC").last.gender
    #else
      return read_attribute(:gender)
    #end
  end

  def correct_gender user, gender
    return nil if !(["Male", "Female", "Unknown"].include? gender)
    self.account_gender_judgments.create({:user_id=>user.id, :gender=>gender})
    self.gender = gender
    self.save
    return gender
  end

  def get_account_suggestion
    return account_suggestion if self.account_suggestion
    self.build_account_suggestion
    return self.account_suggestion
  end

  def suggested?
    suggestion = self.account_suggestion
    return false if suggestion.nil?
    return suggestion.users.size > 0 
  end

  def gender_at_time datetime
    judgments = self.account_gender_judgments.where("created_at <= '#{datetime.to_s(:db)}'").order("created_at ASC")
    if judgments.size > 0
      return judgments.last.gender
    else
      return read_attribute(:gender)
    end
  end
end
