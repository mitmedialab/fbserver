require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "gender" do
   assert_equal "Male", accounts(:two).gender
   assert_equal "Unknown", accounts(:three).gender
   accounts(:three).account_gender_judgments.create!({:user_id=>users(:one).id, :gender=>"Male"})
   assert_equal "Male", accounts(:three).gender
  end

  test "gest suggestion" do
    assert_equal accounts(:one).account_suggestion, accounts(:one).get_account_suggestion

    assert_equal nil, accounts(:five).account_suggestion

    assert_equal 0, accounts(:five).get_account_suggestion.users.size
  end

  test "suggestions" do
    users = accounts(:one).account_suggestion.users
    assert_equal 3, users.size
    assert_equal 101, users[0]
    assert_equal 102, users[1]
  end

  test "suggested?" do
    assert_equal true, accounts(:one).suggested?
    assert_equal false, accounts(:two).suggested?
    assert_equal false, accounts(:four).suggested?
  end
end
