
module SmsSafe
  def self.hook!(texter_gem)
    case texter_gem
      when :action_texter
        ActionTexter.register_interceptor(SmsSafe::Interceptors::ActionTexter.new)
      when :twilio
        # TODO: Monkeypatch Twilio::REST::Message#create
        raise "Unimplemented!"
      when :nexmo
        # TODO: Monkeypatch Nexmo::Client#send_message
        raise "Unimplemented!"
      else
        raise InvalidConfigSettingError.new("Ensure texter_gem is either :action_texter, :twilio or :nexmo")
    end
  end
end
