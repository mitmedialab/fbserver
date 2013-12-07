# -*- encoding : utf-8 -*-
class ActivityLog < ActiveRecord::Base
  attr_accessible :user_id, :action, :data
  has_one :user
  validates :user_id, :presence => true
end
