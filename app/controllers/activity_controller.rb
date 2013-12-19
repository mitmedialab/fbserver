class ActivityController < ApplicationController
  def log
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    if(!params[:data].nil?) 
      data = params[:data].to_json
    end
    redirect_to "/" and return if @current_user.nil?

    @current_user.activity_logs.create(:action=>params[:log_action], :data=> data)
    render :json => true
  end
end
