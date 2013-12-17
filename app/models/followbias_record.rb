class FollowbiasRecord < ActiveRecord::Base
  attr_accessible :user_id, :friendsrecord_id, :male, :female, :unknown, :total_following, :created_at
  belongs_to :user
  belongs_to :friendsrecord
end
