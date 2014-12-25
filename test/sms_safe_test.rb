require_relative "test_helper"
require "sms_safe"

class SmsSafeTest < MiniTest::Test
  should "intercept message" do
    i = SmsSafe::Interceptor.new
    assert_equal true, i.intercept_message?(SmsSafe::Message.new(from: "+441111222222", to: "+441111222222", text: "blah"))
  end
end
