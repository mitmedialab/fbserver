require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "gender" do
   assert_equal "Male", accounts(:two).gender
   account = accounts(:three)
   assert_equal "Unknown", account.gender
  end

  test "correct gender" do
    assert_difference 'AccountGenderJudgment.all.size', 1 do
      account = accounts(:three)
      account.correct_gender(users(:one), "Male")
      account.reload
      assert_equal "Male",  account.gender
      agj = account.account_gender_judgments.last
      assert_equal "Male", agj.gender
      assert_equal users(:one).id, agj.user.id
      assert_equal account.id, agj.account.id
    end 
  end

  test "get suggestion" do
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
