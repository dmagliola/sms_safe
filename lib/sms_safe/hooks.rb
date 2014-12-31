
module SmsSafe
  def self.hook!(texter_gem)
    case texter_gem
      when :action_texter
        ActionTexter.register_interceptor(SmsSafe::Interceptors::ActionTexter.new)
      when :twilio
        hook_twilio!
      when :nexmo
        hook_nexmo!
      else
        raise InvalidConfigSettingError.new("Ensure texter_gem is either :action_texter, :twilio or :nexmo")
    end
  end

  private

  def self.hook_nexmo!
    Nexmo::Client.class_eval do
      alias_method :sms_safe_original_send_message, :send_message

      def send_message(params)
        interceptor = SmsSafe::Interceptors::Nexmo.new
        new_message = interceptor.process_message(params)
        if new_message.nil?
          return new_message
        else
          return sms_safe_original_send_message(new_message)
        end
      end
    end
  end

  def self.hook_twilio!
    # TODO: Monkeypatch Twilio::REST::Message#create
    raise "Unimplemented!"
  end
end
