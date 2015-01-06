require "rubygems"

require "simplecov"
require "coveralls"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]
SimpleCov.start
SimpleCov.start do
  add_filter "/test/"
end

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "minitest/autorun"
require "minitest/reporters"
MiniTest::Reporters.use!

require "shoulda"
require "shoulda-context"
require "shoulda-matchers"
require "mocha/setup"

# Make the code to be tested easy to load.
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'active_support/testing/assertions'
include ActiveSupport::Testing::Assertions

require "benchmark"

require 'mail'
require "action_mailer"
ActionMailer::Base.delivery_method = :test
include Mail::Matchers

require "sms_safe"

# Add helper methods to use in the tests
class MiniTest::Test
  # Calls Interceptor#intercept_message? with a bunch of numbers, and checks that they return the expected result
  def check_interception_rules(interceptor, numbers_to_check, expected_result)
    numbers_to_check.each do |number|
      message = SmsSafe::Message.new(from: number, to: number, text: "Foo")
      assert_equal expected_result, interceptor.intercept_message?(message)
    end
  end

  # Calls process_message for a message that should be intercepted.
  # Checks that the message received back is identical to the one sent
  def process_and_assert_identical_message(interceptor, message)
    original_message = message.clone
    result = interceptor.process_message(message)
    refute_nil result
    assert_equal original_message.class, result.class
    assert_equal original_message.from, result.from
    assert_equal original_message.to, result.to
    assert_equal original_message.text, result.text
  end
end

# Empty Interceptor that we can use for testing. Does what normal interceptors do,
# but it does it with our own internal Message class, no converting or anything fancy.
class TestInterceptor < SmsSafe::Interceptor
  def convert_message(message)
    message
  end

  def redirect(message)
    message.to = redirect_phone_number(message)
    message.text = redirect_text(message)
    message
  end
end

class Object
  # Returns a hash with all the instance variables of an object.
  # Useful for comparing equality of objects that are not designed for that
  def instance_variables_hash
    Hash[instance_variables.map { |name| [name, instance_variable_get(name)] } ]
  end
end

# Some sample phone numbers to use in tests
DEFAULT_INTERNAL_PHONE_NUMBER = '+447111222222'
INTERNAL_PHONE_NUMBERS = ['+447111222221', '+447111222222', '+447111222223']
INTERNAL_PHONE_NUMBERS_REGEX = /\+44711122222\d/
INTERNAL_PHONE_NUMBERS_PROC = Proc.new { |m| m.to.start_with?('+447111') && ['1','2','3'].include?(m.to[-1]) }
EXTERNAL_PHONE_NUMBERS = ["+447222333444", "+13125556666"]
