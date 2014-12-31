require_relative "../test_helper"
require "action_texter"

class ActionTexterTest < MiniTest::Test

  # Check that a message that got redirected is being sent to the right recipient, with changed message,
  # but keeps everything else intact
  def check_redirected_message(original_message, redirected_message)
    assert_equal ActionTexter::Message, redirected_message.class # Check that we are returning the original class
    assert_equal original_message.from, redirected_message.from # With intact from
    assert_equal SmsSafe.configuration.redirect_target, redirected_message.to # New recipient
    assert_operator original_message.text.length, :<, redirected_message.text.length # Modified text
    assert_match original_message.text, redirected_message.text # that includes the original message
    assert_equal original_message.reference, redirected_message.reference # and with intact extra attributes
  end

  context "With an ActionTexter interceptor" do
    setup do
      SmsSafe.configure do |config|
        config.internal_phone_numbers = INTERNAL_PHONE_NUMBERS
        config.intercept_mechanism = :redirect
        config.redirect_target = DEFAULT_INTERNAL_PHONE_NUMBER
      end

      @interceptor = SmsSafe::Interceptors::ActionTexter.new
      @original_message = ActionTexter::Message.new(from: DEFAULT_INTERNAL_PHONE_NUMBER, to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo", reference: "message_reference-1234")
    end

    should "convert Message" do
      converted_message = @interceptor.convert_message(@original_message.clone)

      assert_equal SmsSafe::Message, converted_message.class # Check that we converted into our internal class
      assert_equal @original_message.from, converted_message.from # Check that the important attributes are conserved
      assert_equal @original_message.to, converted_message.to
      assert_equal @original_message.text, converted_message.text
      assert_equal @original_message.instance_variables_hash, converted_message.original_message.instance_variables_hash # Check that the original messages with its extra attributes are conserved
      assert_equal @original_message.reference, converted_message.original_message.reference
    end

    should "modify message recipient and text when redirecting" do
      converted_message = @interceptor.convert_message(@original_message.clone)
      redirected_message = @interceptor.redirect(converted_message)
      check_redirected_message(@original_message, redirected_message)
    end

    context "With a redirect intercept" do
      should "return modified message if intercepting" do
        result = @interceptor.delivering_sms(@original_message.clone)
        check_redirected_message(@original_message, result)
      end
      should "return original message if not intercepting" do
        @original_message.to = DEFAULT_INTERNAL_PHONE_NUMBER
        message = @original_message.clone
        result = @interceptor.delivering_sms(message)

        refute_nil result
        assert_equal @original_message.class, result.class # We get back the correct class,
        assert_equal message.object_id, result.object_id # the same exact object we passed in
        assert_equal @original_message.instance_variables_hash, result.instance_variables_hash # with the same attributes we always had (need to check this since it could be returning a modified object)
      end
    end

    context "With a discard intercept" do
      setup do
        SmsSafe.configure do |config|
          config.intercept_mechanism = :discard
          config.discard_delay = 0
        end
      end
      should "return nil if intercepting a message" do
        result = @interceptor.delivering_sms(@original_message.clone)
        assert_nil result
      end
    end
  end
end
