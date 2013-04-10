require 'test_helper'
require 'json'

class UserTest < ActiveSupport::TestCase
  test "all friends" do
    friends = users(:one).all_friends
    assert_equal 4, friends.size
    assert_equal accounts(:three).uuid, friends[0].uuid #verify sorting
    assert friends.include? accounts(:one)
  end

  test "follow bias" do
    assert_equal nil,  users(:four).followbias
    bias = users(:one).followbias
    assert_equal 2, bias[:male]
    assert_equal 1, bias[:female]
    assert_equal 1, bias[:unknown]
  end

end
