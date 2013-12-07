require 'test_helper'
require 'json'

class ActivityLogTest < ActiveSupport::TestCase
  test "create activity log" do
    assert_difference 'ActivityLog.all.size', 1 do 
      users(:one).activity_logs.create(:action=>"test activity log", :data=>"1")
    end
  end
end
