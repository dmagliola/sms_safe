# SmsSafe

[![Build Status](https://travis-ci.org/dmagliola/sms_safe.svg?branch=master)](https://travis-ci.org/dmagliola/sms_safe)
[![Coverage Status](https://coveralls.io/repos/dmagliola/sms_safe/badge.png?branch=master)](https://coveralls.io/r/dmagliola/sms_safe?branch=master)
[![Code Climate](https://codeclimate.com/github/dmagliola/sms_safe/badges/gpa.svg)](https://codeclimate.com/github/dmagliola/sms_safe)
[![Inline docs](http://inch-ci.org/github/dmagliola/sms_safe.svg?branch=master&style=flat)](http://inch-ci.org/github/dmagliola/sms_safe)
[![Gem Version](https://badge.fury.io/rb/sms_safe.png)](http://badge.fury.io/rb/sms_safe)
[![Dependency Status](https://gemnasium.com/dmagliola/sms_safe.svg)](https://gemnasium.com/dmagliola/sms_safe)


SMS safe provides a safety net while you're developing an application that sends SMS.
It keeps SMS messages from escaping into the wild.

Inspired by [MailSafe](https://rubygems.org/gems/mail_safe), it is essentially "MailSafe for SMS".

Once you've installed and configured this gem, you can rest assured that your app won't send
SMS messages to external phone numbers.

Messages going to your own, internal phone numbers will still go through normally, however, anything else will
either get sent to you instead (via SMS or Email), or discarded.

## Download

Gem: `gem install sms_safe`

## Installation

Load the gem in the appropriate environments in your GemFile. For example, I'm loading this in Gemfile as:

  `gem "sms_safe", group: [:development, :staging]`

IMPORTANT: Be sure not to load this in your production environment, otherwise, your SMS won't be sent to the proper
recipients. In your test environment, you may or may not want this depending on how you are dealing with SMS right now.

We recommend using [ActionTexter](https://rubygems.org/gems/action_texter) to send your SMS, which already provides
for a very good way of switching SMS off in your test environment, while giving you testable objects that you can use
to check your logic.


## Configuration

You should configure SmsSafe in the same initializer that you use for your SMS, so you can make sure that it runs
after your Texter gem has been configured.

```
SmsSafe.configure do |config|
  config.internal_phone_numbers = ['+12223334444', '+447111222222']
  config.intercept_mechanism = :redirect
  config.redirect_target = '+12223334444'
end

SmsSafe.hook!(:action_texter) # or :twilio or :nexmo

```

Call hook! **after** setting the configuration for your texter gem.

The configuration specifies:

- **internal_phone_numbers:** SMS sent to these numbers will be sent normally. These can be specified
       as a String, Regex, Proc, or an array of the same. Any phone number that doesn't match these is
       considered external, and its SMS will get intercepted. If left empty, **all** SMS will be intercepted.
- **intercept_mechanism:** Whether to `:redirect` (default), `:email` or `:discard` the SMS sent to an external number.
- **redirect_target:** If `:redirect`ing, SMS will be sent to this number instead of the original recipient.
      Can be a String or a Proc
- **email_target:** If `:email`ing, SMS will be sent as an e-mail to this e-mail address. Can be a String or a Proc
- **discard_delay:** [ms] If `:discard`ing, a delay this long will be introduced, for slightly more realistic
      performance characteristics.


## Interception mechanisms

When an SMS is being sent to a phone number that is not recognized as internal, it gets intercepted
and it will be processed according to the `intercept_mechanism` configured.

**IMPORTANT!**

If you choose to `:email` or `:discard` instead of `:redirect`ing, then when you send a message
the return value from your texter gem can be nil if the SMS does get intercepted.
You need to account for that, and consider it a successful send for your app logic.


### Redirection

SMS will be sent anyway, but to the number specified by `redirect_target`.

A string "(SmsSafe: #{original_phone_number})" will be added, so you know it was meant for a different number.

### Emailing

Instead of sending the SMS, an e-mail will be sent to the address specified by `email_target`, describing all the information about the SMS.
This is useful in dev / staging as a less annoying alternative to SMS'ing yourself, and also
for teams, since multiple people may end up having access to the e-mail, as opposed to an SMS.

### Discarding

In some cases, you just don't care, you simply don't want to be notified. This is particularly useful
if you are doing load testing / stress testing, where millions of SMS / emails might end up being sent to you.

For this scenario, we include the `discard_delay` setting, which will make the "sending" take longer
than a simple discard. You should set this to an average value that your SMS provider exhibits. This way,
even if you are queueing SMS sending using Resque / DelayedJob, you can still check that, when dealing with
a real load, your queue workers can keep up with the demand.


## Supported Libraries

SmsSafe can currently hook into the following texter gems:

- **(ActionTexter)[https://rubygems.org/gems/action_texter]**
- (Nexmo)[https://rubygems.org/gems/nexmo]
- (Twilio Ruby)[https://rubygems.org/gems/twilio-ruby]

Of these 3, ActionTexter is the only one that provides useful functionality for automated testing,
and functionality for interceptors / observers. It also works natively with both Twilio and Nexmo,
so we recommend it extensively.

For Nexmo and Twilio Ruby, unfortunately, the way we hook is by monkey-patching them. This works,
but it's not ideal, so we recommend using ActionTexter if you come.

If you would like the SmsSafe functionality but you use another SMS provider / gem, you can add the new provider
and submit a Pull Request (see bottom of README), add the new provider to (ActionTexter)[https://github.com/watu/action_texter],
or just ask, I'd like to extend this gem as much as possible.


## Version Compatibility and Continuous Integration

Tested with [Travis](https://travis-ci.org/dmagliola/sms_safe) using Ruby 1.9.3, 2.0, 2.1.1, 2.1.2, 2.1.3 and 2.1.5,
 and against mail 2.6.3, 2.6.1, 2.5.4, 2.5.3 and 2.4.4.

To locally run tests do:

````
appraisal rake test
```

## Copyright

Copyright (c) 2014, 2015, Daniel Magliola

See LICENSE for details.


## Users

This gem is being used by:

- [MSTY](https://www.msty.com)
- You? please, let us know if you are using this gem.


## Changelog

### Version 1.0.0 (Jan 2nd, 2015)
- Newly released gem, supports ActionTexter, Nexmo and Twilio.
- Still waiting to make sure Mail configuration works transparently for both Mail and ActionMailer.
- Also waiting to figure out how to get Coveralls to recognize the true coverage (aka 100%)


## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Code your thing
1. Write and run tests:
        bundle install
        appraisal
        appraisal rake test
1. Write documentation and make sure it looks good: yard server --reload
1. Add items to the changelog, in README.
1. Commit your changes (`git commit -am "Add some feature"`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request
