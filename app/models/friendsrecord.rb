class Friendsrecord < ActiveRecord::Base
  belongs_to :users
  # attr_accessible :title, :body
end
