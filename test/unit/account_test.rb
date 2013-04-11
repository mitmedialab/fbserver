require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "gender" do
   assert_equal "Male", accounts(:two).gender
   assert_equal "Unknown", accounts(:three).gender
   accounts(:three).account_gender_judgments.create!({:user_id=>users(:one).id, :gender=>"Male"})
   assert_equal "Male", accounts(:three).gender
  end
end
