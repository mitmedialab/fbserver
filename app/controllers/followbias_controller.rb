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
    return if @user.nil?
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

  def index
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
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
