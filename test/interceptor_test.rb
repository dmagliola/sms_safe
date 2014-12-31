require_relative "test_helper"

DEFAULT_INTERNAL_PHONE_NUMBER = '+447111222222'
INTERNAL_PHONE_NUMBERS = ['+447111222221', '+447111222222', '+447111222223']
INTERNAL_PHONE_NUMBERS_REGEX = /\+44711122222\d/
INTERNAL_PHONE_NUMBERS_PROC = Proc.new { |m| m.to.start_with?('+447111') && ['1','2','3'].include?(m.to[-1]) }
EXTERNAL_PHONE_NUMBERS = ["+447222333444", "+13125556666"]

class InterceptorTest < MiniTest::Test
  context "With a Base Interceptor" do
    setup do
      @interceptor = SmsSafe::Interceptor.new
      @message = SmsSafe::Message.new(from: EXTERNAL_PHONE_NUMBERS.first, to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
    end

    should "raise an exception if calling convert_message" do
      assert_raises(RuntimeError) do
        @interceptor.convert_message(@message)
      end
    end

    should "raise an exception if calling redirect" do
      assert_raises(RuntimeError) do
        @interceptor.redirect(@message)
      end
    end
  end

  context "With a Test Interceptor" do
    setup do
      @interceptor = TestInterceptor.new

      SmsSafe.configure do |config|
        config.internal_phone_numbers = INTERNAL_PHONE_NUMBERS
        config.intercept_mechanism = :redirect
        config.redirect_target = DEFAULT_INTERNAL_PHONE_NUMBER
      end

      @internal_message = SmsSafe::Message.new(from: INTERNAL_PHONE_NUMBERS.first, to: INTERNAL_PHONE_NUMBERS.last, text: "Foo") # Doesn't get intercepted
      @external_message = SmsSafe::Message.new(from: INTERNAL_PHONE_NUMBERS.first, to: EXTERNAL_PHONE_NUMBERS.last, text: "Bar") # Gets intercepted
    end

    context "intercepting by String" do
      setup do
        SmsSafe.configure { |config| config.internal_phone_numbers = DEFAULT_INTERNAL_PHONE_NUMBER }
      end

      should "choose to intercept message for non-matching numbers" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, [DEFAULT_INTERNAL_PHONE_NUMBER], false)
      end
    end

    context "intercepting by Regex" do
      setup do
        SmsSafe.configure { |config| config.internal_phone_numbers = INTERNAL_PHONE_NUMBERS_REGEX }
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, INTERNAL_PHONE_NUMBERS, false)
      end
    end

    context "intercepting by Proc" do
      setup do
        SmsSafe.configure { |config| config.internal_phone_numbers = INTERNAL_PHONE_NUMBERS_PROC }
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, INTERNAL_PHONE_NUMBERS, false)
      end
    end

    context "intercepting by Mixture of methods" do
      setup do
        SmsSafe.configure { |config| config.internal_phone_numbers = [DEFAULT_INTERNAL_PHONE_NUMBER, INTERNAL_PHONE_NUMBERS_REGEX, INTERNAL_PHONE_NUMBERS_PROC] }
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, INTERNAL_PHONE_NUMBERS, false)
      end
    end

    context "intercepting by Invalid Comparison Method" do
      setup do
        SmsSafe.configure { |config| config.internal_phone_numbers = 5 } # An Integer is not a valid rule for comparison
      end

      should "raise exception" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          check_interception_rules(@interceptor, INTERNAL_PHONE_NUMBERS, false)
        end
      end
    end

    context "intercepting by Redirecting" do
      # The logic inside redirect is tested within each of the interceptors, not here
      should "return an intercepted message if intercepting" do
        original_message = @external_message.clone
        result = @interceptor.process_message(@external_message)
        refute_nil result
        assert_equal SmsSafe::Message, result.class
        assert_operator original_message.text.length, :<=, result.text.length # Message length must have increased
        assert_match original_message.text, result.text # New message must include the original one
        refute_equal original_message.to, result.to # Recipient must have changed
        assert_equal SmsSafe.configuration.redirect_target, result.to # Recipient must be redirect target
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @internal_message)
      end
    end

    context "intercepting by Emailing" do
      setup do
        SmsSafe.configure do |config|
          config.intercept_mechanism = :email
          config.email_target = 'blah@blah.com'
        end
      end

      should "send an email and return nil if intercepting" do
        original_message = @external_message.clone
        assert_difference "Mail::TestMailer.deliveries.length", +1 do
          result = @interceptor.process_message(@external_message)
          assert_nil result
        end

        mail = Mail::TestMailer.deliveries.last

        assert have_sent_email.from('blah@blah.com').matches?(mail)
        assert have_sent_email.to('blah@blah.com').matches?(mail)
        assert_match original_message.text, mail.body.to_s # Email must contain original SMS text, from and to
        assert_match original_message.from, mail.body.to_s
        assert_match original_message.to, mail.body.to_s
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @internal_message)
      end
    end

    context "intercepting by Discarding" do
      setup do
        SmsSafe.configure do |config|
          config.intercept_mechanism = :discard
          config.discard_delay = 0
        end
      end

      should "return immediately and return nil if intercepting without delay" do
        time_to_run = Benchmark.realtime do
          result = @interceptor.process_message(@external_message)
          assert_nil result
        end
        assert_operator 20, :>=, time_to_run * 1000 # Must take less than 20ms (arbitrary number picked to show there's no delay)
      end

      context "with delay" do
        setup do
          SmsSafe.configure { |config| config.discard_delay = 100 } # Delay by 100ms
          end
        should "delay and return nil if intercepting with delay" do
          time_to_run = Benchmark.realtime do
            result = @interceptor.process_message(@external_message)
            assert_nil result
          end
          assert_operator 100, :<=, time_to_run * 1000 # Must take at least 100ms
        end
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @internal_message)
      end
    end

    context "intercepting by Invalid Mechanism" do
      setup do
        SmsSafe.configure { |config| config.intercept_mechanism = :invalid }
      end

      should "raise an exception if intercepting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.process_message(@external_message)
        end
      end
    end

    context "resolving target phone number by Proc" do
      setup do
        SmsSafe.configure { |config| config.redirect_target = Proc.new { |m| "#{m.to}#123" } }
      end
      should "redirect to the appropriate phone number" do
        result = @interceptor.redirect_phone_number(@external_message)
        assert_equal @external_message.to + "#123", result
      end
    end

    context "resolving target phone number by Invalid Method" do
      setup do
        SmsSafe.configure { |config| config.redirect_target = /5/ } # A regex is not a valid target
      end
      should "raise an exception if redirecting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.redirect_phone_number(@external_message)
        end
      end
    end

    context "resolving target email by Proc" do
      setup do
        SmsSafe.configure { |config| config.email_target = Proc.new { |m| "#{m.to}@blah.com" } }
      end
      should "email to the appropriate address" do
        result = @interceptor.email_recipient(@external_message)
        assert_equal @external_message.to + "@blah.com", result
      end
    end

    context "resolving target email by Invalid Method" do
      setup do
        SmsSafe.configure { |config| config.email_target = /5/ } # A regex is not a valid target
      end
      should "raise an exception if redirecting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.email_recipient(@external_message)
        end
      end
    end
  end # context "With a base Interceptor"
end
