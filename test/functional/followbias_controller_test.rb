require 'test_helper'
require 'json'

class FollowbiasControllerTest < ActionController::TestCase

  test "show followbias" do
    get :show, :id=>users(:one).screen_name
    assert_redirected_to "/"

    assert_difference 'ActivityLog.all.size', 1 do
      session[:user_id] = users(:one).id
      get :show, :id => users(:one).screen_name
      assert_equal users(:one), assigns(:user)
      assert_equal 2, assigns(:followbias)[:male]
      assert_equal 1, assigns(:followbias)[:female]
      assert_equal 1, assigns(:followbias)[:unknown]
      assert_equal 4, assigns(:followbias)[:total_following]
    end
  end

  test 'show page of corrections' do
    get :show_page, :id=>users(:one).screen_name, :page=>0
    assert_redirected_to "/"

    session[:user_id ] = users(:one).id

    assert_difference 'ActivityLog.all.size', 1 do
      get :show_page, :format=>'json', :id=>users(:one).screen_name, :page=>0
      assert_equal 4, assigns(:friends).size
      json_data = JSON.load(response.body)
      assert_equal 1, json_data["next_page"]
    end
    
    assert_difference 'ActivityLog.all.size', 1 do
      get :show_page, :format=>'json', :id=>users(:one).screen_name, :page=>1
      assert_equal 0, assigns(:friends).size
      json_data = JSON.load(response.body)
      assert_equal nil, json_data["next_page"]
    end
    
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
    assert_difference 'ActivityLog.all.size', 1 do
      get :main, nil, {:user_id=>users(:two).id}
      assert_response :success
    end
  end

  test "toggle user suggests account" do

    # no authentication
    post :toggle_suggest, :uuid => "corporation"
    assert_redirected_to "/"

    session[:user_id] = users(:one).id
    # not female, can't suggest
    post :toggle_suggest, :format=>'json', :uuid => accounts(:seven).uuid
    assert_response :success
    json_data = JSON.load(response.body)
    assert_equal accounts(:seven).uuid, json_data["account_id"]
    assert_equal false, json_data["status"]
    assert_equal false, users(:one).suggests_account?(accounts(:seven))

    # female, can suggest, toggle to true
    user = users(:one)
    post :toggle_suggest, :format=>'json', :uuid => accounts(:five).uuid
    assert_response :success
    json_data = JSON.load(response.body)
    assert_equal accounts(:five).uuid, json_data["account_id"]
    assert_equal true, json_data["status"]
    user.reload
    assert_equal true, user.suggests_account?(accounts(:five))

    # female, can suggest, toggle to false
    post :toggle_suggest, :format=>'json', :uuid => accounts(:five).uuid
    assert_response :success
    json_data = JSON.load(response.body)
    assert_equal accounts(:five).uuid, json_data["account_id"]
    assert_equal false, json_data["status"]
    user.reload
    assert_equal false, user.suggests_account?(accounts(:five))
  end


  test "receive random account suggestions for user three" do
    # no authentication
    get :receive_suggestions, :format=>'json'
    assert_redirected_to "/"

    session[:user_id] = users(:three)
    get :receive_suggestions, :format=>'json'
    assert_response :success
    rdata = JSON.load(response.body)
    assert_equal 0, rdata["accounts"].size
  end

  test "receive random account suggestions for user one" do
    users(:four).suggest_account(accounts(:seven))
    session[:user_id] = users(:one)
    get :receive_suggestions, :format=>'json'
    assert_response :success
    rdata = JSON.load(response.body)
    assert_equal 1, rdata["accounts"].size
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

  test "final survey" do
    ## TODO: recreate authenticity token and post survey results
    ## assert that survey is added
    ## assert_difference 'ActivityLog.all.size', 1 do
    assert true
  end
end
