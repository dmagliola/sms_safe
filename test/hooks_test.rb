require_relative "test_helper"
require "action_texter"
require "nexmo"
require "twilio"

# These are the real integration tests. Each one of these installs the hook, then tried sending an SMS
#   that will and will not get intercepted, and check that that actually happens.
class HooksTest < MiniTest::Test
  context "With a basic configuration for SmsSafe" do
    setup do
      SmsSafe.configure do |config|
        config.internal_phone_numbers = INTERNAL_PHONE_NUMBERS
        config.intercept_mechanism = :discard
        config.redirect_target = DEFAULT_INTERNAL_PHONE_NUMBER
      end
    end

    should "hook ActionTexter" do
      SmsSafe.hook!(:action_texter)

      # Mock stuff
      # Try to send a message
      # Check that return is nil
      # Check that nothing got sent
      # Change configuration to redirect
      # Try to send a message
      # Check that return is appropriate
      # Check that something got sent
      # Check that the something that got sent was modified

    end

    should "hook Nexmo" do
      assert_equal true, "Unimplemented"
    end
    should "hook Twilio" do
      assert_equal true, "Unimplemented"
    end
  end
end
