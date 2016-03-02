require 'test_helper'

class SegmentTest < ActiveSupport::TestCase
  test "segment fixtures" do
    segment = segments(:one)
    assert_equal "Journalists", segment.name
    assert_equal "CTL", segment.subsegment

    assert_equal 2, segment.users.size
  end
end
