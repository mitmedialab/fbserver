require 'test_helper'

class ActivityControllerTest < ActionController::TestCase
  test "receive activity log requests" do

    assert_no_difference 'ActivityLog.all.size' do
      get :log, :action=>"test"
      assert_redirected_to "/"
    end

    session[:user_id] = users(:one).id
    assert_difference 'ActivityLog.all.size', 1 do
      get :log, :action=>"test"
    end
  end
end
