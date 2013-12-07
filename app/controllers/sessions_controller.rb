# -*- encoding : utf-8 -*-
class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)
    if(user.twitter_token.nil? or user.twitter_secret.nil?)
      user.twitter_token = auth.credentials.token
      user.twitter_secret = auth.credentials.secret
      user.save!
    end
    session[:user_id] = user.id
    user.activity_logs.create(:action=>"login")
    redirect_to "/followbias/main", :notice => "Signed in!"
  end

  def destroy
    session[:user_id] = nil
    user.activity_logs.create(:action=>"signout")
    redirect_to root_url, :notice => "Signed out!"
  end
end
