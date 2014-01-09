require 'test_helper'

class NameGenderTest < ActiveSupport::TestCase
  test "handles nils properly" do
    ng = NameGender.new
    assert_equal "Unknown", ng.process(nil)[:result]
    assert_equal "Unknown", ng.process("")[:result]
    assert_equal "Unknown", ng.process("   ")[:result]
  end
end
