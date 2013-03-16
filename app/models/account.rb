class Account < ActiveRecord::Base
  attr_accessible :uuid, :screen_name, :name, :gender, :profile_image_url
end
