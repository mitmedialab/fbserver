class SoonController < ApplicationController

  def index
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    redirect_to "/" and return if @current_user.nil?
    render :layout=>"main"
  end

end
