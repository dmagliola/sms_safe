require_relative "test_helper"

EXTERNAL_PHONE_NUMBERS = ["+447222333444", "+13125556666"]

class InterceptorTest < MiniTest::Test
  context "With a Base Interceptor" do
    setup do
      @interceptor = SmsSafe::Interceptor.new
    end

    should "raise an exception if calling convert_message" do
      assert_raises(RuntimeError) do
        @interceptor.convert_message({})
      end
    end

    should "raise an exception if calling redirect" do
      assert_raises(RuntimeError) do
        message = SmsSafe::Message.new(from: EXTERNAL_PHONE_NUMBERS.first, to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
        @interceptor.redirect(message)
      end
    end
  end

  context "With a Test Interceptor" do
    setup do
      @interceptor = TestInterceptor.new
    end

    context "intercepting by String" do
      setup do
        @internal_phone_numbers = ['+447111222222'] # Only one that matches
        SmsSafe.configure { |config| config.internal_phone_numbers = '+447111222222' }
      end

      should "choose to intercept message for non-matching numbers" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, @internal_phone_numbers, false)
      end
    end

    context "intercepting by Regex" do
      setup do
        @internal_phone_numbers = ['+447111222221', '+447111222222', '+447111222223']
        SmsSafe.configure { |config| config.internal_phone_numbers = /\+44711122222\d/ }
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, @internal_phone_numbers, false)
      end
    end

    context "intercepting by Proc" do
      setup do
        @internal_phone_numbers = ['+447111000007', '+447111001007', '+447111002007']
        SmsSafe.configure { |config| config.internal_phone_numbers = Proc.new { |m| m.to.start_with?('+447111') && m.to.end_with?('7') } }
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, @internal_phone_numbers, false)
      end
    end

    context "intercepting by Mixture of methods" do
      setup do
        @internal_phone_numbers = ['+447111222222', '+447111222221', '+447111222222', '+447111222223', '+447111000007', '+447111001007', '+447111002007']
        SmsSafe.configure do |config|
          config.internal_phone_numbers = ['+447111222222', /\+44711122222\d/, Proc.new { |m| m.to.start_with?('+447111') && m.to.end_with?('7') }]
        end
      end

      should "choose to intercept message for non-matching number" do
        check_interception_rules(@interceptor, EXTERNAL_PHONE_NUMBERS, true)
      end

      should "not choose to intercept message for internal number" do
        check_interception_rules(@interceptor, @internal_phone_numbers, false)
      end
    end

    context "intercepting by Invalid Comparison Method" do
      setup do
        @internal_phone_numbers = ['+447111222222']
        SmsSafe.configure { |config| config.internal_phone_numbers = 5 } # An Integer is not a valid rule for comparison
      end

      should "raise exception" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          check_interception_rules(@interceptor, @internal_phone_numbers, false)
        end
      end
    end

    context "intercepting by Redirecting" do
      setup do
        SmsSafe.configure do |config|
          config.internal_phone_numbers = ['+447111222222', '+447111222223', '+447111222224']
          config.intercept_mechanism = :redirect
          config.redirect_target = '+447111222222'
        end

        @message = SmsSafe::Message.new(from: '+447111222223', to: '+447111222224', text: "Foo")
      end

      # The logic inside redirect is tested within each of the interceptors, not here
      should "return an intercepted message if intercepting" do
        @message.to = EXTERNAL_PHONE_NUMBERS.first # Get it to intercept
        @original_message = @message.clone
        result = @interceptor.process_message(@message)
        refute_nil result
        assert_equal SmsSafe::Message, result.class
        assert_operator @original_message.text.length, :<=, result.text.length # Message length must have increased
        assert_match @original_message.text, result.text # New message must include the original one
        refute_equal @original_message.to, result.to # Recipient must have changed
        assert_equal SmsSafe.configuration.redirect_target, result.to # Recipient must be redirect target
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @message)
      end
    end

    context "intercepting by Emailing" do
      setup do
        SmsSafe.configure do |config|
          config.internal_phone_numbers = ['+447111222222', '+447111222223', '+447111222224']
          config.intercept_mechanism = :email
          config.email_target = 'blah@blah.com'
        end

        @message = SmsSafe::Message.new(from: '+447111222223', to: '+447111222224', text: "Foo")
      end

      should "send an email and return nil if intercepting" do
        @message.to = EXTERNAL_PHONE_NUMBERS.first # Get it to intercept
        @original_message = @message.clone
        assert_difference "Mail::TestMailer.deliveries.length", +1 do
          result = @interceptor.process_message(@message)
          assert_nil result
        end

        mail = Mail::TestMailer.deliveries.last

        assert have_sent_email.from('blah@blah.com').matches?(mail)
        assert have_sent_email.to('blah@blah.com').matches?(mail)
        assert_match @original_message.text, mail.body.to_s # Email must contain original SMS text, from and to
        assert_match @original_message.from, mail.body.to_s
        assert_match @original_message.to, mail.body.to_s
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @message)
      end
    end

    context "intercepting by Discarding" do
      setup do
        SmsSafe.configure do |config|
          config.internal_phone_numbers = ['+447111222222', '+447111222223', '+447111222224']
          config.intercept_mechanism = :discard
          config.discard_delay = 0
        end

        @message = SmsSafe::Message.new(from: '+447111222223', to: '+447111222224', text: "Foo")
      end

      should "return immediately and return nil if intercepting without delay" do
        @message.to = EXTERNAL_PHONE_NUMBERS.first # Get it to intercept
        time_to_run = Benchmark.realtime do
          result = @interceptor.process_message(@message)
          assert_nil result
        end
        assert_operator 20, :>=, time_to_run * 1000 # Must take less than 20ms (arbitrary number picked to show there's no delay)
      end

      context "with delay" do
        setup do
          SmsSafe.configure { |config| config.discard_delay = 100 } # Delay by 100ms
          end
        should "delay and return nil if intercepting with delay" do
          @message.to = EXTERNAL_PHONE_NUMBERS.first # Get it to intercept
          time_to_run = Benchmark.realtime do
            result = @interceptor.process_message(@message)
            assert_nil result
          end
          assert_operator 100, :<=, time_to_run * 1000 # Must take at least 100ms
        end
      end

      should "return an identical message if not intercepting" do
        process_and_assert_identical_message(@interceptor, @message)
      end
    end

    context "intercepting by Invalid Mechanism" do
      setup do
        SmsSafe.configure do |config|
          config.internal_phone_numbers = ['+447111222222', '+447111222223', '+447111222224']
          config.intercept_mechanism = :invalid
        end
        @message = SmsSafe::Message.new(from: '+447111222223', to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
      end

      should "raise an exception if intercepting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.process_message(@message)
        end
      end
    end

    context "resolving target phone number by Proc" do
      setup do
        SmsSafe.configure { |config| config.redirect_target = Proc.new { |m| "#{m.to}#123" } }
        @message = SmsSafe::Message.new(from: '+447111222223', to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
      end
      should "redirect to the appropriate phone number" do
        result = @interceptor.redirect_phone_number(@message)
        assert_equal @message.to + "#123", result
      end
    end

    context "resolving target phone number by Invalid Method" do
      setup do
        SmsSafe.configure { |config| config.redirect_target = /5/ } # A regex is not a valid target
        @message = SmsSafe::Message.new(from: '+447111222223', to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
      end
      should "raise an exception if redirecting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.redirect_phone_number(@message)
        end
      end
    end

    context "resolving target email by Proc" do
      setup do
        SmsSafe.configure { |config| config.email_target = Proc.new { |m| "#{m.to}@blah.com" } }
        @message = SmsSafe::Message.new(from: '+447111222223', to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
      end
      should "email to the appropriate address" do
        result = @interceptor.email_recipient(@message)
        assert_equal @message.to + "@blah.com", result
      end
    end

    context "resolving target email by Invalid Method" do
      setup do
        SmsSafe.configure { |config| config.email_target = /5/ } # A regex is not a valid target
        @message = SmsSafe::Message.new(from: '+447111222223', to: EXTERNAL_PHONE_NUMBERS.first, text: "Foo")
      end
      should "raise an exception if redirecting" do
        assert_raises(SmsSafe::InvalidConfigSettingError) do
          @interceptor.email_recipient(@message)
        end
      end
    end
  end # context "With a base Interceptor"
end
