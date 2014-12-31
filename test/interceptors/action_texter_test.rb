require_relative "../test_helper"
require "sms_safe"
require "action_texter"

class ActionTexterTest < MiniTest::Test
  should "Convert Message" do
    assert_equal true, "Unimplemented"
  end

  should "Modify message recipient and text when redirecting" do
    assert_equal true, "Unimplemented"
  end

  context "With a discard intercept" do
    should "return nil if intercepting a message" do
      assert_equal true, "Unimplemented"
    end
    should "return original message if not intercepting" do
      assert_equal true, "Unimplemented"
    end
  end
  context "With a redirect intercept" do
    should "return modified message if intercepting" do
      assert_equal true, "Unimplemented"
    end
  end
end
