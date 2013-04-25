# -*- encoding : utf-8 -*-
require "resque"
#require 'resque/plugins/lock'
require 'resque-lock-timeout'

#stub class
class ProcessUserFriends
  extend Resque::Plugins::LockTimeout
  @queue = :fetchfriends
  @lock_timeout = 3600
  def self.perform(authdata)
  end
end

class FollowbiasController < ApplicationController
  
  def show
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    @user = User.find_by_screen_name(params[:id])
    redirect_to "/" and return if @user.nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user
    @friends = @user.all_friends.sort{|a,b| a.gender <=> b.gender}
    @followbias = @user.followbias
    respond_to do |format|
      format.html{
        render :layout=> false
      }
      format.json{
        render :json => @followbias
      }
    end
  end

  def show_page

    page_size = 25
    
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @user = User.find_by_screen_name(params[:id])
    redirect_to "/" and return if @user.nil? or params[:page].nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user

    @friends = @user.all_friends_paged(page_size, page_size * params[:page].to_i)

    next_page = params[:page].to_i + 1
    next_page = nil if @friends.size == 0

    respond_to do |format|
      format.json{
        render :json => {:friends=>@friends, :next_page=>next_page, :page_size => page_size}
      }
    end
  end

  def show_gender_samples
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @user = User.find_by_screen_name(params[:id])
    redirect_to "/" and return if @user.nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user
    respond_to do |format|
      format.json{
        render :json => {:friends=>@user.sample_friends.shuffle}
      }
    end
  end

  def correct
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    render :json =>{:status=>"error"} and return if @current_user.nil?
    #redirect_to "/" and return if @current_user.nil?

    @account = Account.find_by_uuid(params[:id])
    render :json =>{:status=>"error", :params=>params} and return if @account.nil?
    #redirect_to "/" and return if @account.nil?
    
    if ["Female", "Male", "Unknown"].include? params[:gender]
      @account.account_gender_judgments.create! :user_id=>@current_user.id, :gender=>params[:gender]
    end

    render :json => {:account => @account.screen_name, :gender=> @account.gender}
  end
  
  def start
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to :controller=>"followbias", :action=>"index" and return if @current_user
    render :layout=>"start"
  end

  def main
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to "/" and return if @current_user.nil?
    
    #send the control group and all new users to the "soon" page
    redirect_to "/soon" and return if @current_user.treatment == "ctl" or @current_user.treatment == "new"
 
    authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                :oauth_token => @current_user['twitter_token'],
                :oauth_token_secret => @current_user['twitter_secret']}
    Resque.enqueue(ProcessUserFriends, authdata)
    render :layout=>"main"
  end

  def index
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to "/" and return if @current_user.nil?
    redirect_to "/followbias/main" if !@current_user.nil?
    if(!@current_user.nil?)

      authdata = {:consumer_key => ENV['TWITTER_CONSUMER_KEY'],
                  :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
                  :oauth_token => @current_user['twitter_token'],
                  :oauth_token_secret => @current_user['twitter_secret']}
      #if(@current_user.friends.nil? or @current_user.friends=="")
        Resque.enqueue(ProcessUserFriends, authdata)
      #end
      @follows = []
      @followers = []
    else
      @followers = []
    end
  end
end
