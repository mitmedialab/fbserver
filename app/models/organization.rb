class Organization < ActiveRecord::Base
  attr_accessible :name, :state, :city, :twitter_lists
  has_and_belongs_to_many :users
end
