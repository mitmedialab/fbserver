require 'test_helper'

class AccountSuggestionTest < ActiveSupport::TestCase

  test "model links" do
    suggestions = account_suggestions(:one)
    account = accounts(:one)
    assert_equal account.id, suggestions.account.id

    account_suggestion = account.account_suggestion
    assert_equal suggestions.id, account_suggestion.id
  end

  test "suggesting accounts" do
    one = account_suggestions(:one)
    users = one.users
    assert_equal 3, users.size
    assert_equal 101, users[0]
    assert_equal 102, users[1]
  end

  test "add user" do
    assert_difference 'account_suggestions(:two).users.size', 1 do
      account_suggestions(:two).add_user users(:two)
    end

    assert_no_difference 'account_suggestions(:one).users.size' do
      account_suggestions(:two).add_user users(:one)
    end
    
  end
end
