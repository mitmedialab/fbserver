# -*- encoding : utf-8 -*-
class Friendsrecord < ActiveRecord::Base
  belongs_to :user
  has_many :followbias_records
  attr_accessible :user, :friends
end
