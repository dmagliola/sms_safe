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

      @action_texter_client = ActionTexter::TestClient.new
    end

    should "hook ActionTexter" do
      ActionTexter::Client.setup("Test") # Excellent, no need to mock stuff up! Thank you ActionTexter!
      SmsSafe.hook!(:action_texter)

      # Try to send an external message
      @action_texter_client.deliveries.clear
      message = ActionTexter::Message.new(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo", reference: "ref-1")
      result = message.deliver

      # Check that return is nil and that nothing got sent
      assert_nil result
      assert_equal 0, @action_texter_client.deliveries.length

      # Change configuration to redirect
      SmsSafe.configuration.intercept_mechanism = :redirect

      # Try to send an external message
      @action_texter_client.deliveries.clear
      message = ActionTexter::Message.new(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo", reference: "ref-1")
      result = message.deliver

      # Check that return is appropriate and that something got sent, redirected and with changed text
      refute_nil result
      assert_equal 1, @action_texter_client.deliveries.length
      assert_equal DEFAULT_INTERNAL_PHONE_NUMBER, @action_texter_client.deliveries.last.to
      assert_operator "Foo".length, :<, @action_texter_client.deliveries.last.text.length

      # Try to send an internal message
      @action_texter_client.deliveries.clear
      message = ActionTexter::Message.new(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: INTERNAL_PHONE_NUMBERS.last, text: "Foo", reference: "ref-1")
      result = message.deliver

      # Check that it got delivered, unchanged
      refute_nil result
      assert_equal 1, @action_texter_client.deliveries.length
      assert_equal INTERNAL_PHONE_NUMBERS.last, @action_texter_client.deliveries.last.to
      assert_equal "Foo", @action_texter_client.deliveries.last.text
    end

    should "hook Nexmo" do
      assert_equal true, "Unimplemented"
    end
    should "hook Twilio" do
      assert_equal true, "Unimplemented"
    end
  end
end
