require 'test_helper'
require 'json'

class UserTest < ActiveSupport::TestCase
  test "all friends" do
    friends = users(:one).all_friends
    assert_equal 4, friends.size
    assert_equal accounts(:one).uuid, friends[0].uuid #verify sorting
    assert friends.include? accounts(:one)
  end

  test "friendrecords" do
    assert_equal 2, users(:three).friendsrecords.size
    assert_equal 1, users(:three).friendrecords.size
  end

  test "all friends paged" do
    friends = users(:one).all_friends_paged(2, 1)
    assert_equal 2, friends.size
    assert_not_equal accounts(:three).uuid, friends[0].uuid
  end

  test "all friends paged, gender sorted" do
    friends = users(:one).all_friends_paged(2,0,"suggest")
    assert_not_equal nil, friends
    #friends.each{|i|puts i.screen_name}
    assert_equal accounts(:five).uuid, friends[0].uuid
  end

  test "followbias"  do
    assert_no_difference 'users(:system).followbias_records.size' do
      assert_equal nil,  users(:system).followbias
    end

    # setup: cache followbias record
    user = users(:one)
    user.cache_followbias_record

    # make sure that followbias doesn't create a new followbias_record
    # if one already exists
    assert_no_difference 'user.followbias_records.size' do
      bias = user.followbias
      assert_equal 2, bias[:male]
      assert_equal 1, bias[:female]
      assert_equal 1, bias[:unknown]
    end

    #now change the gender of an account and assert the same followbias
    lois = accounts(:two)
    lois.correct_gender(user, "Female")
    assert_no_difference 'user.followbias_records.size' do
      bias = user.followbias
      assert_equal 2, bias[:male]
      assert_equal 1, bias[:female]
      assert_equal 1, bias[:unknown]
    end

    #now update the cache and expect the followbias to change
    user.reload
    fbr = user.followbias_records.last
    #updating time so the latest record does get returned as .last
    fbr.created_at = 1.day.ago 
    fbr.save!
   
    user.cache_followbias_record
    assert_no_difference 'user.followbias_records.size' do
      bias = user.followbias
      assert_equal 1, bias[:male]
      assert_equal 2, bias[:female]
      assert_equal 1, bias[:unknown]
    end

  end

  test "cache followbias record only if the followbias has changed" do
    user = users(:one)
    # create first followbias record cache
    user.cache_followbias_record
    assert_no_difference 'user.followbias_records.size' do
      #don't update the followbias record cache if it hasn't changed
      user.cache_followbias_record
    end

    #now change the gender of an account. A new cache entry should be created
    assert_difference 'user.followbias_records.size', 1 do
      lois = accounts(:two)
      lois.correct_gender(user, "Female")
      user.cache_followbias_record
    end
  end

  test "follow bias cache" do
    empty = {:male=>0, :female=>0 , :unknown=>0, :total_following=>0, :account=>"nofriends"}

    assert_no_difference 'users(:system).followbias_records.size' do
      assert_equal nil,  users(:system).cache_followbias_record
    end

    assert_difference 'users(:four).followbias_records.size', 1 do
      assert_equal empty,  users(:four).cache_followbias_record
    end

    assert_difference 'users(:one).followbias_records.size', 1 do
      bias = users(:one).cache_followbias_record
      assert_equal 2, bias[:male]
      assert_equal 1, bias[:female]
      assert_equal 1, bias[:unknown]
    end
  end

  test "show gender samples" do
    assert_equal 6, users(:three).sample_friends.size
    assert_equal 4, users(:one).sample_friends.size
  end

  test "suggest account" do 
    assert_no_difference 'accounts(:one).account_suggestion.users.size' do
      assert_no_difference 'users(:one).all_suggested_accounts.size' do
        users(:one).suggest_account(accounts(:one))
      end
    end

    assert_difference 'users(:four).all_suggested_accounts.size', 1 do
      assert_equal nil, accounts(:two).account_suggestion
      users(:four).suggest_account(accounts(:two))
      assert !accounts(:two).account_suggestion.nil?
    end

  end 

  test "unsuggest account" do

    assert_difference 'accounts(:one).account_suggestion.users.size', -1 do
      assert_difference 'users(:one).all_suggested_accounts.size', -1 do
        users(:one).unsuggest_account(accounts(:one))
      end
    end

    assert_no_difference 'users(:four).all_suggested_accounts.size'  do
       users(:four).unsuggest_account(accounts(:one))
    end
    
  end

  test "all suggested accounts" do
    assert_equal 2, users(:one).all_suggested_accounts.size
    assert_equal 1, users(:two).all_suggested_accounts.size
    assert_equal 2, users(:three).all_suggested_accounts.size
    assert_equal 0, users(:four).all_suggested_accounts.size
  end


  test "receive random suggestions" do
    users(:four).suggest_account(accounts(:seven))
    assert_equal 0, users(:three).receive_random_suggestions(100).size
    assert_equal 1, users(:one).receive_random_suggestions(100).size
    assert_equal 3, users(:four).receive_random_suggestions(100).size
    assert_equal 2, users(:four).receive_random_suggestions(2).size

    assert_equal "Account", users(:one).receive_random_suggestions(3)[0].class.name
    assert_equal "Account", users(:four).receive_random_suggestions(2)[0].class.name
  end

  test "retrieve userstats" do
    assert_nil users(:two).userstats
    assert_equal 49264, users(:three).userstats['followers_count']
  end

end
