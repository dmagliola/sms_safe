# TODO: Figure out which gems are there, and hook into them

if defined?(ActionTexter)
  ActionTexter.register_interceptor(SmsSafe::Interceptors::ActionTexter.new)
end

# TODO: Monkeypatch Twilio::REST::Message#create
# TODO: Monkeypatch Nexmo::Client#send_message
