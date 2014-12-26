require_relative "test_helper"
require "sms_safe"

class InterceptorTest < MiniTest::Test
  context "Intercepting by String" do
    should "choose to intercept message for non-matching number" do
    end

    should "not choose to intercept message for internal number" do
    end
  end

  context "Intercepting by Regex" do
    should "choose to intercept message for non-matching number" do
    end

    should "not choose to intercept message for internal number" do
    end
  end

  context "Intercepting by Proc" do
    should "choose to intercept message for non-matching number" do
    end

    should "not choose to intercept message for internal number" do
    end
  end

  context "Intercepting by Mixture of methods" do
    should "choose to intercept message for non-matching number" do
    end

    should "not choose to intercept message for internal number" do
    end
  end

  context "Intercepting by Invalid Comparison Method" do
    should "raise exception" do
    end
  end

  context "Intercepting by redirecting" do
    should "Return a message with a different recipient and text if intercepting" do
      # Check the text!
    end

    should "Return an identical message if not intercepting" do
    end
  end

  context "Intercepting by emailing" do
    should "Send an email and return nil if intercepting" do
    end

    should "Return an identical message if not intercepting" do
    end
  end

  context "Intercepting by discarding" do
    should "Return immediately and return nil if intercepting without delay" do
    end

    should "Delay and return nil if intercepting with delay" do
    end

    should "Return an identical message if not intercepting" do
    end
  end

  context "Intercepting by invalid mechanism" do
    should "Raise an exception if intercepting" do
    end
  end

  context "Resolving target phone number by Proc" do
    should "Redirect to the appropriate phone number" do
    end
  end

  context "Resolving target phone number by Invalid Method" do
    should "Raise an exception if redirecting" do
    end
  end

  context "Resolving target email by Proc" do
    should "Email to the appropriate address" do
    end
  end

  context "Resolving target email by Invalid Method" do
    should "Raise an exception if redirecting" do
    end
  end

  context "Using the base class directly" do
    should "Raise an exception if calling convert_message" do
    end

    should "Raise an exception if calling redirect" do
    end
  end
end
