require_relative "../test_helper"
require "sms_safe"
require "nexmo"

class NexmoTest < MiniTest::Test
  should "Convert Message" do
  end

  should "Modify message recipient and text when redirecting" do
  end

  context "With a discard intercept" do
    should "return nil if intercepting a message" do
    end
    should "return original message if not intercepting" do
    end
  end
  context "With a redirect intercept" do
    should "return modified message if intercepting" do
    end
  end
end
