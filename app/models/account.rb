# -*- encoding : utf-8 -*-
class Account < ActiveRecord::Base
  attr_accessible :uuid, :screen_name, :name, :gender, :profile_image_url
  has_many :account_gender_judgments
  def gender
    if self.account_gender_judgments.size >  0
      return self.account_gender_judgments.last.gender
    else
      read_attribute(:gender)
    end
  end
end
