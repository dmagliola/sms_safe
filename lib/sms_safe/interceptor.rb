require 'mail'

module SmsSafe

  # When a message is intercepted, Interceptor decides whether we need to do anything with it,
  #   and does it.
  # The different adaptor classes in the Interceptors module provide mapping to each of the SMS libraries peculiarities.
  class Interceptor

    # Method called by all the sub-classes to process the SMS being sent
    # @param [Object] message the message we intercepted from the texter gem. May be of varying types, depending
    #   on which texter gem is being used.
    # @returns [Object] the message to send (if modified recipient / text), of the same type we received
    #   or nil if no SMS should be sent
    def process_message(original_message)
      message = convert_message(original_message)

      if intercept_message?(message)
        intercept_message!(message)
      else
        original_message
      end
    end

    # Decides whether to intercept the message that is being sent, or to let it go through
    # @param [Message] message the message we are evaluating
    # @returns [Boolean] whether to intercept the message (true) or let it go through (false)
    def intercept_message?(message)
      matching_rules = [SmsSafe.configuration.internal_phone_numbers].flatten.compact
      internal_recipient = matching_rules.any? do |rule|
        case rule
          when String then message.to == rule
          when Regexp then !!(message.to =~ rule)
          when Proc   then rule.call(message)
          else
            raise InvalidConfigSettingError.new("Ensure internal_phone_numbers is a String, a Regexp or a Proc (or an array of them). It was: #{SmsSafe.configuration.internal_phone_numbers.inspect}")
        end
      end
      !internal_recipient # Intercept messages that are *not* going to one of the allowed numbers
    end

    # Once we've decided to intercept the message, act on it, based on the intercept_mechanism set
    # @param [Message] message the message we are evaluating
    # @returns [Object] the message to send, of the type that corresponds to the texter gem (if :redirecting)
    #   or nil to cancel sending (if :email or :discard)
    def intercept_message!(message)
      case SmsSafe.configuration.intercept_mechanism
        when :redirect then redirect(message)
        when :email then email(message)
        when :discard then discard
        else
          raise InvalidConfigSettingError.new("Ensure intercept_mechanism is either :redirect, :email or :discard. It was: #{SmsSafe.configuration.intercept_mechanism.inspect}")
      end
    end

    # Decides which phone number to redirect the message to
    # @param [Message] message the message we are redirecting
    # @returns [String] the phone number to redirect the number to
    def redirect_phone_number(message)
      target = SmsSafe.configuration.redirect_target
      case target
        when String then target
        when Proc   then target.call(message)
        else
          raise InvalidConfigSettingError.new("Ensure redirect_target is a String or a Proc. It was: #{SmsSafe.configuration.redirect_target.inspect}")
      end
    end

    # Modifies the text of the message to indicate it was redirected
    # Simply appends "(SmsSafe: original_recipient_number)", for brevity
    #
    # @param [Message] message the message we are redirecting
    # @returns [String] the new text for the SMS
    def redirect_text(message)
      "#{message.text} (SmsSafe: #{message.to})"
    end

    # Sends an e-mail to the specified address, instead of
    def email(message)
      message_body = <<-EOS
This email was originally an SMS that SmsSafe intercepted:

From: #{message.from}
To: #{message.to}
Text: #{message.text}

Full object: #{message.original_message.inspect}
      EOS

      recipient = email_recipient(message)

      mail = Mail.new do
        from     recipient
        to       recipient
        subject  'SmsSafe: #{message.to} - #{message.text}'
        body     message_body
      end
      mail.deliver!

      # Must return nil to stop the sending
      nil
    end

    # Decides which email address to send the SMS to
    # @param [Message] message the message we are emailing
    # @returns [String] the email address to email it to
    def email_recipient(message)
      target = SmsSafe.configuration.email_target
      case target
        when String then target
        when Proc   then target.call(message)
        else
          raise InvalidConfigSettingError.new("Ensure email_target is a String or a Proc. It was: #{SmsSafe.configuration.email_target.inspect}")
      end
    end

    # Discards the message. Essentially doesn't do anything. Will sleep for a bit, however, if
    #   configuration.discard_delay is set.
    def discard
      # Delay to simulate the time it takes to talk to the external service
      if !SmsSafe.configuration.discard_delay.nil? && SmsSafe.configuration.discard_delay > 0
        delay = SmsSafe.configuration.discard_delay.to_f / 1000 # delay is specified in ms
        sleep delay
      end

      # Must return nil to stop the sending
      nil
    end

    # Converts an SMS message from whatever object the texter gem uses into our generic Message
    # Must be overridden by each gem's interceptor
    #
    # @param [Object] message that is being sent
    # @returns [Message] the message converted into our own Message class
    def convert_message(message)
      raise "Must override!"
    end

    # Returns a modified version of the original message with new recipient and text,
    #   to give back to the texter gem to send.
    # Must be overridden by each gem's interceptor
    # Call redirect_phone_number and redirect_text to get the new recipient and text, and
    #  modify message.original_message
    #
    # @param [Message] message that is being sent, unmodified
    # @returns [Object] modified message to send, of the type the texter gem uses
    def redirect(message)
      raise "Must override!"
    end
  end
end