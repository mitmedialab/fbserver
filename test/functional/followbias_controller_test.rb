require 'test_helper'

class FollowbiasControllerTest < ActionController::TestCase
  test "show followbias" do
    get :show, :id=> users(:one).screen_name
    assert_equal users(:one), assigns(:user)
    assert_equal 1, assigns(:followbias)[:male]
    assert_equal 2, assigns(:followbias)[:female]
    assert_equal 1, assigns(:followbias)[:unknown]
    assert_equal 4, assigns(:followbias)[:total_following]
  end
end
