module SmsSafe

  class InvalidConfigSettingError < StandardError; end

  def self.configuration
    @configuration ||=  Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  class Configuration

    # List of phone numbers that can accept SMS. Any phone number not on this list will get the SMS intercepted
    # Leaving this empty means *all* SMS are intercepted, which is a valid use case.
    # Value can be a String, a Regex, or a Proc to determine whether the phone is internal or not.
    # Value can also be an Array, in which case the SMS will be allowed to go through if *any* of the entries match.
    attr_accessor :internal_phone_numbers

    # What to do with intercepted messages.
    # Options are:
    #   :redirect - send SMS to another number. Must set redirect_target option
    #   :email - send an Email instead. Must set email_target option.
    #   :discard - don't send anything. May want to set discard_delay if simulating load
    attr_accessor :intercept_mechanism

    # The target number where messages are redirected, if intercept mechanism is :redirect
    # Value can be a string or a Proc that returns a string
    attr_accessor :redirect_target

    # The target email where messages are sent, instead of sending SMS, if intercept mechanism is :email
    # Value can be a string or a Proc that returns a string
    attr_accessor :email_target

    # If you are doing stress testing, you don't want to send out millions of SMS or Emails, so discarding is the
    #   way to go. However, this may give you an unrealistic view of how many SMS you can send per minute, distorting
    #   the results of the stress test. Discard delay introduces a little `sleep` whilst discarding, to compensate for that.
    # Defaults to 100ms
    # Specify it in ms
    attr_accessor :discard_delay

    def initialize
      @internal_phone_numbers = []
      @intercept_mechanism = 'redirect'
      @discard_delay = 50 # 50 milliseconds
    end
  end
end