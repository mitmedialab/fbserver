require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  test "organization fixtures" do
    org = organizations(:one)
    assert_equal "PA", org.state
    assert_equal "Lancaster", org.city

    assert_equal 2, org.users.size
  end
end
