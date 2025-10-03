#!/usr/bin/env ruby
# frozen_string_literal: true

# This example demonstrates how Gmail message IDs encode timestamps
# Based on: https://www.metaspike.com/dates-gmail-message-id-thread-id-timestamps/
#
# Gmail Message IDs are hexadecimal values where the first part (all but last 5 digits)
# encodes the timestamp in milliseconds since epoch.

require "time"

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

def decode_gmail_message_id(message_id)
  # Drop last 5 digits to get the timestamp part
  timestamp_hex = message_id[0..-6]

  # Convert from hex to milliseconds
  timestamp_ms = timestamp_hex.to_i(16)

  # Convert to Time object
  Time.at(timestamp_ms / 1000.0)
end

puts "Gmail Message ID Generation Demo"
puts "=" * 50
puts

# Example 1: Generate a message ID for the current time
puts "Example 1: Current timestamp"
current_time = Time.now
message_id = generate_gmail_message_id(current_time)
decoded_time = decode_gmail_message_id(message_id)

puts "Original time:  #{current_time}"
puts "Message ID:     #{message_id}"
puts "Decoded time:   #{decoded_time}"
puts "Match:          #{(current_time - decoded_time).abs < 0.001}"
puts

# Example 2: Examples from the article
puts "Example 2: Known Gmail message IDs from the article"
examples = {
  "172ed79b0337c14f" => "Thursday, June 25, 2020 9:54:34.675 PM (UTC)",
  "ffff3432161af8b" => "Wednesday, November 3, 2004 4:11:11.254 PM (UTC)"
}

examples.each do |msg_id, expected_date|
  decoded = decode_gmail_message_id(msg_id)
  puts "Message ID:     #{msg_id}"
  puts "Expected:       #{expected_date}"
  puts "Decoded:        #{decoded.utc}"
  puts
end

# Example 3: Generate IDs for specific dates
puts "Example 3: Generate IDs for specific dates"
dates = [
  Time.parse("2020-01-01 00:00:00 UTC"),
  Time.parse("2023-06-15 12:30:45 UTC"),
  Time.parse("2024-12-25 18:45:00 UTC")
]

dates.each do |date|
  msg_id = generate_gmail_message_id(date)
  decoded = decode_gmail_message_id(msg_id)
  puts "Original:       #{date}"
  puts "Message ID:     #{msg_id}"
  puts "Decoded:        #{decoded}"
  puts "Accurate:       #{(date - decoded).abs < 0.001}"
  puts
end

# Example 4: Using a seeded Random for reproducible IDs (useful for testing)
puts "Example 4: Reproducible IDs with seeded Random"
test_time = Time.parse("2024-06-15 12:00:00 UTC")
seeded_random = Random.new(12345)

# Generate the same ID twice with the same seed
id1 = generate_gmail_message_id(test_time, random: seeded_random)
seeded_random = Random.new(12345) # Reset seed
id2 = generate_gmail_message_id(test_time, random: seeded_random)

puts "Time:           #{test_time}"
puts "ID (seed 1):    #{id1}"
puts "ID (seed 2):    #{id2}"
puts "Reproducible:   #{id1 == id2}"
puts

# Generate different IDs with different seeds
seeded_random1 = Random.new(11111)
seeded_random2 = Random.new(22222)
id_a = generate_gmail_message_id(test_time, random: seeded_random1)
id_b = generate_gmail_message_id(test_time, random: seeded_random2)

puts "ID (seed 11111): #{id_a}"
puts "ID (seed 22222): #{id_b}"
puts "Different:       #{id_a != id_b}"
puts

puts "=" * 50
puts "Key Points:"
puts "- Message IDs are 15-16 hexadecimal digits"
puts "- First (n-5) digits encode timestamp in milliseconds"
puts "- Last 5 digits are random for uniqueness"
puts "- Overflow happened on Nov 3, 2004 (10 → 11 digits for timestamp)"
puts "- Optional random: parameter allows reproducible testing"
puts "- Uses bytes for ~10x faster random generation"
