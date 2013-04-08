require "resque"

#stub class
class ProcessUserFriends
  @queue = :fetchfriends
  def self.perform(authdata)
  end
end

class FollowbiasController < ApplicationController
  
  def show
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    @user = User.find_by_screen_name(params[:id])
    @friends = @user.all_friends.sort{|a,b| a.gender <=> b.gender}
    redirect_to "/" and return if @user.nil?
    redirect_to "/" and return if @current_user.nil? or @current_user != @user
    @followbias = @user.followbias
    respond_to do |format|
      format.html{
        render :layout=> false
      }
      format.json{
        render :json => @followbias
      }
    end
    #TODO: show only yourself
    #return if @current_user!=@user
  end

  def correct
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    render :json =>{:status=>"error"} and return if @current_user.nil?
    #redirect_to "/" and return if @current_user.nil?

    @account = Account.find_by_screen_name(params[:screen_name])
    render :json =>{:status=>"error"} and return if @account.nil?
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
    #redirect_to "/" and return if @current_user.nil?
    render :layout=>"main"
  end

  def index
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
    redirect_to "/" and return if @current_user.nil?
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
