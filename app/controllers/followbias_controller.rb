# -*- encoding : utf-8 -*-
require "resque"
#require 'resque/plugins/lock'
require 'resque-lock-timeout'
require 'digest/sha1'
require 'json'

#stub class
class ProcessUserFriends
  extend Resque::Plugins::LockTimeout
  @queue = "fetchfriends#{Rails.env}".to_sym
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

    @current_user.activity_logs.create(:action => "followbias/show",
      :data => {:followbias=>@followbias, :friends=>@friends}.to_json)
    respond_to do |format|
      format.html{
        render :layout=> false
      }
      format.json{
        render :json => @followbias
      }
    end
  end


  #TODO: at some point, refactor with show_page
  def show_gender_sorted_page
    page_size = 25

    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @user = User.find_by_screen_name(params[:id])
    redirect_to "/" and return if @user.nil? or params[:page].nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user

    @friends = @user.all_friends_paged(page_size, page_size * params[:page].to_i, "suggest").collect{|friend|
      status = ""
      status = "selected" if @user.suggests_account? friend
      {:gender => friend.gender,
       :id => friend.id,
       :uuid => friend.uuid,
       :name => friend.name,
       :profile_image_url => friend.profile_image_url,
       :screen_name => friend.screen_name,
       :selected => status}
    }

    next_page = params[:page].to_i + 1
    next_page = nil if @friends.size == 0

    @current_user.activity_logs.create(:action => "followbias/show_gender_sorted_page",
      :data => {:page=>params[:page]}.to_json)

    respond_to do |format|
      format.html{
        render :layout=> false
      }
      format.json{
        render :json => {:friends=>@friends, :next_page=>next_page, :page_size => page_size}   
      }
    end
  end

  def show_page

    page_size = 25
    
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @user = User.find_by_screen_name(params[:id])
    redirect_to "/" and return if @user.nil? or params[:page].nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user

    @friends = @user.all_friends_paged(page_size, page_size * params[:page].to_i).collect{|friend|
      status = "" 
      status = "selected" if @user.suggests_account? friend
      {:gender => friend.gender,
       :id => friend.id,
       :uuid => friend.uuid,
       :name => friend.name,
       :profile_image_url => friend.profile_image_url,
       :screen_name => friend.screen_name,
       :selected => status}
    }

    next_page = params[:page].to_i + 1
    next_page = nil if @friends.size == 0

    @current_user.activity_logs.create(:action => "followbias/show_page",
      :data => {:page=>params[:page]}.to_json)

    respond_to do |format|
      format.html{
        render :layout=> false
      }
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

    # TODO: REFACTOR THIS CODE SNIPPET
    @friends = @user.sample_friends.shuffle.collect{|friend|
      status = ""
      status = "selected" if @user.suggests_account? friend
      {:gender => friend.gender,
       :id => friend.id,
       :uuid => friend.uuid,
       :name => friend.name,
       :profile_image_url => friend.profile_image_url,
       :screen_name => friend.screen_name,
       :selected => status}
    }


    respond_to do |format|
      format.json{
        render :json => {:friends=>@friends}
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
      @account.correct_gender(@current_user, params[:gender])
    end

    @current_user.activity_logs.create(:action => "followbias/correct",
      :data => {:account=>@account.uuid, 
      :id=>@account.account_gender_judgments.last.id})
    render :json => {:account => @account.screen_name, :gender=> @account.gender}
  end

  def toggle_suggest
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    redirect_to "/" and return if @current_user.nil?

    @account = Account.find_by_uuid(params[:uuid])
    @status = nil

    # make a change if the account is female or we're unsuggesting
    if(@account.gender == "Female" or @current_user.suggests_account? @account)

      if(@current_user.suggests_account? @account)
        @current_user.unsuggest_account @account
        @status = false
      else
        @current_user.suggest_account @account
        @status = true
      end

    @current_user.activity_logs.create(:action => "followbias/toggle_suggest",
      :data => {:account=>@account.uuid})

    else
      @status = false
    end

    respond_to do |format|
      format.json{
        render :json => {:status => @status,
                         :account_id => @account.uuid}
      }
    end
  end

  def receive_suggestions
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    redirect_to "/" and return if @current_user.nil?
   
    accounts = @current_user.receive_random_suggestions(10)

    respond_to do |format|
      format.html{
        render :layout=> false
      }
      format.json{
        render :json => {:accounts=>accounts}
      }
    end
  end
  
  def start
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to :controller=>"followbias", :action=>"index" and return if @current_user
    render :layout=>"start"
  end

  def main
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to "/" and return if @current_user.nil?

    #  redirect test subjects to survey unless they have been reffered by the survey
    #  or they have taken the survey previously
    if(!@current_user.survey_complete and 
       (@current_user.treatment == "ctl" or @current_user.treatment == "test"))
      if(!params.has_key? "survey")
        @current_user.activity_logs.create(:action => "redirect_to_pre_survey")
        redirect_to ENV_SURVEYS[@current_user.id % ENV_SURVEYS.size] + "&user_id=#{Digest::SHA1.hexdigest(@current_user.screen_name)}"and return
      else
        @current_user.activity_logs.create(:action => "pre_survey_complete")
        @current_user.survey_complete = true
        @current_user.save!
      end
    end
    #send the control group and all new users to the "soon" page
    if @current_user.treatment == "ctl" or @current_user.treatment == "new"
      redirect_to "/soon" and return 
    end

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


  def final_survey
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to "/" and return if @current_user.nil?
    result = params
    result.delete("authenticity_token")
    @current_user.activity_logs.create(:action => "final_survey_complete")
    #if(@current_user.post_survey.nil?)
      @current_user.post_survey = result.to_json
      @current_user.save!
    #end
    render :nothing => true
  end

end
