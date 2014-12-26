require_relative "test_helper"
require "sms_safe"
require "action_texter"
require "nexmo"
require "twilio"

# These are the real integration tests. Each one of these installs the hook, then tried sending an SMS
#   that will and will not get intercepted, and check that that actually happens.
class HooksTest < MiniTest::Test
  context "With a basic configuration for SmsSafe" do
    should "Hook ActionTexter" do
    end
    should "Hook Nexmo" do
    end
    should "Hook Twilio" do
    end
  end
end