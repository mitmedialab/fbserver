class Segment < ActiveRecord::Base
  attr_accessible :name, :subsegment
  has_and_belongs_to_many :users
end
