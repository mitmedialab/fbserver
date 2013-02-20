class User < ActiveRecord::Base
  attr_accessible :name, :provider, :uid
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.screen_name = auth["info"]["nickname"]
      user.twitter_token =  auth['credentials']['token']
      user.twitter_secret = auth['credentials']['secret']
      puts auth['credentials']
    end
  end
end
