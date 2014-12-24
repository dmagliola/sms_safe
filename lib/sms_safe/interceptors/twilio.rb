module SmsSafe
  module Interceptors
    class Twilio < SmsSafe::Interceptor
      # This method will be called differently for each Texter Gem, it's the one that the hook likes to call
      # In all cases, it's a one-liner that calls process_message in the superclass
      # It could even be an alias, for all practical purposes
      # def delivering_sms(message)
      #   self.process_message(message)
      # end

      # Converts a hash of params (Twilio's call is just a hash to Client.messages) into Message
      # @param [Hash] message that is being sent by Twilio gem
      # @returns [Message] the message converted into our own Message class
      def convert_message(message)
        SmsSafe::Message.new(from: message[:from], to: message[:to], text: message[:body], original_message: message)
      end

      # Returns a modified version of the original message with new recipient and text,
      #   to give back to the texter gem to send.
      #
      # @param [Message] message that is being sent, unmodified
      # @returns [Hash] modified message to send
      def redirect(message)
        original_message = message.original_message
        original_message[:to] = redirect_phone_number(message)
        original_message[:text] = redirect_text(message)
        original_message
      end
    end
  end
end