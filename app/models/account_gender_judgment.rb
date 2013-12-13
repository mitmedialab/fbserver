# -*- encoding : utf-8 -*-
class AccountGenderJudgment < ActiveRecord::Base
  attr_accessible :account_id, :user_id, :gender, :created_at
  belongs_to :account
  belongs_to :user
  validates :account_id, :presence => true
  validates :user_id, :presence => true
end
