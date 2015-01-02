module SmsSafe

  # Different texter gems will have different classes for their messages.
  # This is a common class that acts as an impedance adapter. Most of our methods use this class
  #
  # @!attribute from
  #   @return [String] name or phone number of the author of the message.
  # @!attribute to
  #   @return [String] phone number of the recipient of the message.
  # @!attribute text
  #   @return [String] actual message to send.
  # @!attribute original_message
  #   @return [String] original message sent by the texter gem, unmapped.
  class Message
    attr_accessor :from, :to, :text, :original_message

    # Set all params as internal values.
    # @param [Hash] attrs accepts :from, :to, :text and :original_message
    def initialize(attrs)
      attrs.each { |k, v| self.send "#{k.to_s}=".to_sym, v }
    end
  end
end