require_relative "test_helper"
require "action_texter"
require "nexmo"
require "twilio-ruby"

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
      nexmo = Nexmo::Client.new(key: "blah", secret: "bleh")
      SmsSafe.hook!(:nexmo)

      # Stub the "post" method so that it doesn't actually do a post
      # I'm doing that instead of stubbing "send_message", since we're already monkeypatching send_message, and I don't want those two to collide
      nexmo.expects(:post).never

      # Try to send an external message
      result = nexmo.send_message(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, text: 'Foo')

      # Check that return is nil and that nothing got sent
      assert_nil result

      # Change configuration to redirect
      SmsSafe.configuration.intercept_mechanism = :redirect

      # Stub again so that it validates the parameters we want
      nexmo.expects(:post).
          once.
          with() { |path, params| params[:to] == DEFAULT_INTERNAL_PHONE_NUMBER && params[:text].length > 'Foo'.length && params[:text].include?('Foo') }.
          returns({ 'messages' => ['status' => 0, 'message-id' => '123456']})

      # Try to send an external message
      result = nexmo.send_message(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, text: 'Foo')

      # Check that return is appropriate. The rest got checked in the stub
      refute_nil result

      # Stub again so that it validates the parameters we want
      nexmo.expects(:post).
          once.
          with() { |path, params| params[:to] == INTERNAL_PHONE_NUMBERS.last && params[:text] = 'Foo' }.
          returns({ 'messages' => ['status' => 0, 'message-id' => '123456']})

      # Try to send an internal message
      result = nexmo.send_message(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: INTERNAL_PHONE_NUMBERS.last, text: 'Foo')

      # Check that it got delivered. The rest got checked in the stub
      refute_nil result
    end

    should "hook Twilio" do
      twilio = Twilio::REST::Client.new 'blah', 'bleh'
      SmsSafe.hook!(:twilio)

      # Stub the "post" method so that it doesn't actually do a post
      # I'm doing that instead of stubbing "send_message", since we're already monkeypatching send_message, and I don't want those two to collide
      twilio.expects(:post).never

      # Try to send an external message
      result = twilio.messages.create(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first,  body: 'Foo')

      # Check that return is nil and that nothing got sent
      assert_nil result

      # Change configuration to redirect
      SmsSafe.configuration.intercept_mechanism = :redirect

      # Stub again so that it validates the parameters we want
      twilio.expects(:post).
          once.
          with() { |path, params| params[:to] == DEFAULT_INTERNAL_PHONE_NUMBER && params[:body].length > 'Foo'.length && params[:body].include?('Foo') }.
          returns({ 'sid' => 'Message01'})

      # Try to send an external message
      result = twilio.messages.create(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, body: 'Foo')

      # Check that return is appropriate. The rest got checked in the stub
      refute_nil result

      # Stub again so that it validates the parameters we want
      twilio.expects(:post).
          once.
          with() { |path, params| params[:to] == INTERNAL_PHONE_NUMBERS.last && params[:body] = 'Foo' }.
          returns({ 'sid' => 'Message01'})

      # Try to send an internal message
      result = twilio.messages.create(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: INTERNAL_PHONE_NUMBERS.last, body: 'Foo')

      # Check that it got delivered. The rest got checked in the stub
      refute_nil result
    end

    should "raise if hooking an invalid library" do
      assert_raises(SmsSafe::InvalidConfigSettingError) do
        SmsSafe.hook!(:invalid)
      end
    end
  end
end
