# -*- encoding : utf-8 -*-
class AccountGenderJudgment < ActiveRecord::Base
  attr_accessible :account_id, :user_id, :gender
  has_one :account
  has_one :user
  validates :account_id, :presence => true
  validates :user_id, :presence => true
end
