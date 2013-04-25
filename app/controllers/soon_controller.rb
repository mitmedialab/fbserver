# -*- encoding : utf-8 -*-
require "resque"
#require 'resque/plugins/lock'
require 'resque-lock-timeout'

class ProcessUserFriends
  extend Resque::Plugins::LockTimeout
  @queue = :fetchfriends
  @lock_timeout = 3600
  def self.perform(authdata)
  end
end

class SoonController < ApplicationController

  def index
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    redirect_to "/" and return if @current_user.nil?

    #we calculate the FollowBias for all users, including the control group
    authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                :oauth_token => @current_user['twitter_token'],
                :oauth_token_secret => @current_user['twitter_secret']}
    Resque.enqueue(ProcessUserFriends, authdata)

    render :layout=>"main"
  end

end
