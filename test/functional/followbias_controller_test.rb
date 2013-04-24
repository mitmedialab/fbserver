require 'test_helper'
require 'json'

class FollowbiasControllerTest < ActionController::TestCase

  def setup
  end

  test "show followbias" do
    get :show, :id=>users(:one).screen_name
    assert_redirected_to "/"

    session[:user_id] = users(:one).id
    get :show, :id => users(:one).screen_name
    assert_equal users(:one), assigns(:user)
    assert_equal 2, assigns(:followbias)[:male]
    assert_equal 1, assigns(:followbias)[:female]
    assert_equal 1, assigns(:followbias)[:unknown]
    assert_equal 4, assigns(:followbias)[:total_following]
  end

  test 'show page' do
    get :show_page, :id=>users(:one).screen_name, :page=>0
    assert_redirected_to "/"

    session[:user_id ] = users(:one).id

    get :show_page, :format=>'json', :id=>users(:one).screen_name, :page=>0
    assert_equal 4, assigns(:friends).size
    json_data = JSON.load(response.body)
    assert_equal 1, json_data["next_page"]
    
    get :show_page, :format=>'json', :id=>users(:one).screen_name, :page=>1
    assert_equal 0, assigns(:friends).size
    json_data = JSON.load(response.body)
    assert_equal nil, json_data["next_page"]
    
  end

  test "show sample friends" do
    get :show_page, :id=>users(:one).screen_name, :page=>0
    assert_redirected_to "/"

    session[:user_id ] = users(:three).id
    get :show_gender_samples, :format=>'json',:id => users(:three).screen_name
    assert_response :success
    json_data = JSON.load(response.body)
    assert_equal 6, json_data["friends"].size
    
  end

  test 'main no user' do
    get :main
    assert_redirected_to "/"
  end

  test "main new user" do
    get :main, nil, {:user_id=>users(:one).id}
    assert_redirected_to "/soon"
  end

  test "main control group user" do
    get :main, nil, {:user_id=>users(:three).id}
    assert_redirected_to "/soon"
  end

  test "main test user" do
    get :main, nil, {:user_id=>users(:two).id}
    assert_response :success
  end

  test "correct" do
    post :correct, :screen_name => "maleperson", :gender=>"Unknown"
    assert_equal "error", JSON.load(response.body)["status"]

    session[:user_id] = users(:one).id
    post :correct, :screen_name => "invalid_screen_name", :gender=>"Unknown"

    assert_equal "Male", accounts(:one).gender
    post :correct, :id => accounts(:one).uuid, :gender=>"Unknown"
    accounts(:one).reload
    assert_equal "Unknown", accounts(:one).gender
    assert_equal "Unknown", JSON.load(response.body)["gender"]
  end
end
