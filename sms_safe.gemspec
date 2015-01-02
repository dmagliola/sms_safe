lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sms_safe/version"

Gem::Specification.new do |s|
  s.name        = 'sms_safe'
  s.version     = '1.0.0'
  s.summary     = "Keep your SMS messages from escaping into the wild during development."
  s.description = %q{SmsSafe provides a safety net while you're developing an application that uses ActionTexter
                          or other gems to send SMS. It keeps SMS messages from escaping into the wild.

                          Once you've installed and configured this gem, you can rest assures that your app won't send
                          SMS messages to external phone numbers. Instead, messages will be routed to a phone number
                          you specify, converted into e-mails to you, or simply not sent at all.

                          SmsSafe can also include an artificial delay to simulate the call to your SMS provider,
                          for realistic load testing.}
  s.authors     = ["Daniel Magliola"]
  s.email       = 'dmagliola@crystalgears.com'
  s.homepage    = 'https://github.com/dmagliola/sms_safe'
  s.license     = 'MIT'

  s.files       = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s.features)/})
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 1.9.3"

  s.add_runtime_dependency "mail", '>= 2.4'

  s.add_development_dependency "actionmailer"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"

  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-reporters"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "mocha"
  s.add_development_dependency "simplecov"

  # All the Gems we integrate with, to be able to test the hooks
  s.add_development_dependency "action_texter"
  s.add_development_dependency "twilio-ruby"
  s.add_development_dependency "nexmo"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "codeclimate-test-reporter"
end