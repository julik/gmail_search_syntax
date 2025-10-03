$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "gmail_search_syntax"
require "minitest/autorun"

# Helper module for Gmail message ID generation
module GmailMessageIdHelper
  # Generates a Gmail-style message ID from a timestamp
  # Based on: https://www.metaspike.com/dates-gmail-message-id-thread-id-timestamps/
  #
  # Gmail Message IDs encode the timestamp in the first part (all but last 5 hex digits)
  # To generate: take timestamp in milliseconds, convert to hex, append 5 random hex digits
  #
  # @param time [Time] The timestamp to encode in the message ID
  # @param random [Random, nil] Optional Random instance for reproducible testing
  # @return [String] A hexadecimal Gmail message ID (15-16 digits)
  def generate_gmail_message_id(time, random: Random.new)
    # Get timestamp in milliseconds since epoch
    timestamp_ms = (time.to_f * 1000).to_i
    # Convert timestamp to hex and append first 5 hex digits from random bytes
    timestamp_hex = timestamp_ms.to_s(16)
    # Generate 3 random bytes (24 bits = 6 hex digits, we'll use first 5)
    # Using bytes is much faster than generating individual hex digits
    random_hex = random.bytes(3).unpack1("H*")[0, 5]

    timestamp_hex + random_hex
  end
end
