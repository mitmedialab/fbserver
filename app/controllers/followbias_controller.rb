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
    if(@current_user.friends.nil? or @current_user.friends=="")
      Resque.enqueue(ProcessUserFriends, authdata)
    end
    @follows = []
    @followers = []
    #@follows =0
    #@followers = 0
    #  @client = Twitter::Client.new(
    #    :consumer_key => "4FSppuZFL1fVoEEoppv2zQ",
    #    :consumer_secret => "VocfRmMaIzCjSk5g3QYM1MuZRtaYHk0DGO6aMvGgoE",
    #    :oauth_token => @current_user['twitter_token'],
    #    :oauth_token_secret => @current_user['twitter_secret']
    #  )
    #  @tokens = {:token => @current_user['twitter_token'], :secret=> @current_user['twitter_secret']}
    #
    #
    #  #get friend IDs
    #  cursor = -1
    #  friendship_ids = []
    #  while cursor != 0 do
    #    friendships = @client.friend_ids(@client.user.attrs[:id], {:cursor=>cursor})
    #    cursor = friendships.next_cursor
    #    friendship_ids.concat friendships.ids
    #  end
    #  #friendship_ids = @client.friend_ids.ids

    #  #now get friend info
    #  head = 0
    #  more = true
    #  @follows = friendship_ids
    #  @followers = []
    #  while more
    #    if head + 100 > @follows.size
    #      more = false
    #    end
    #    @followers.concat @client.friendships( @follows[head, 100])
    #    head += 100
    #  end
  
    else
     @followers = []
    end
  end
end
