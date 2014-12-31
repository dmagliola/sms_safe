SmsSafe.configure do |config|
  config.internal_phone_numbers = ['+12223334444', '+447111222222']
  config.intercept_mechanism = :redirect
  config.redirect_target = '+12223334444'
end

Call configure **after** setting the configuration for your texter gem.

SmsSafe.hook!(:action_texter) # or :twilio or :nexmo

Important thing to keep in mind!
If you choose to :email or :discard instead of :redirecting, then when you send a message
the return value from your texter gem can be nil if the SMS does get intercepted.
You need to account for that, and consider it a successful send.

