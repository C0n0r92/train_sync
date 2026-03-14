#!/usr/bin/env ruby

# Setup E2E Test Data for Watch App
# Usage: rails runner watch-app/scripts/setup_test_data.rb

puts "Setting up Watch App E2E test data..."

# Clean up old test data
User.where(email: ["athlete@test.com", "coach@test.com"]).destroy_all
puts "✓ Cleaned old test data"

# Create test athlete
athlete = User.create!(
  email: "athlete@test.com",
  password: "password123",
  password_confirmation: "password123",
  role: :athlete
)
puts "✓ Created test athlete: #{athlete.email}"

# Create device token
device_token = DeviceToken.create!(
  user_id: athlete.id,
  token: "test_device_token_123",
  platform: :connect_iq,
  expires_at: 90.days.from_now
)
puts "✓ Created device token: #{device_token.token}"

# Create test coach
coach = User.create!(
  email: "coach@test.com",
  password: "password123",
  password_confirmation: "password123",
  role: :coach
)
puts "✓ Created test coach: #{coach.email}"

# Create test workout with 3 different block types
workout = coach.workouts.create!(
  name: "E2E Test WOD - 3 Blocks",
  blocks: [
    {
      type: "run",
      target_params: {
        distance: 5,
        pace_target: "6:00"
      }
    },
    {
      type: "rest",
      target_params: {
        duration: 120
      }
    },
    {
      type: "interval",
      target_params: {
        duration: 30,
        reps: 8
      }
    }
  ],
  status: :published
)
puts "✓ Created test workout: #{workout.name} (3 blocks)"

# Create QR code
qr_code = workout.qr_codes.create!(
  short_id: "test123"
)
puts "✓ Created QR code: #{qr_code.short_id}"

# Simulate QR scan
qr_scan = qr_code.qr_scans.create!(
  athlete_id: athlete.id,
  scanned_at: Time.current
)
puts "✓ Created QR scan"

# Create workout session (queued for watch app)
session = WorkoutSession.create!(
  qr_scan_id: qr_scan.id,
  athlete_id: athlete.id,
  workout_id: workout.id,
  started_at: Time.current
)
puts "✓ Created workout session (queued)"

puts "\n" + "="*60
puts "E2E Test Data Ready!"
puts "="*60
puts "\nConfiguration for Watch App (set in source/Main.mc):"
puts "  var API_URL = \"http://localhost:3000/api\";"
puts "\nTest credentials:"
puts "  Device Token: #{device_token.token}"
puts "  Session ID: #{session.id}"
puts "  Athlete ID: #{athlete.id}"
puts "\nExpected API Response from GET /api/sessions/current:"
puts "  Session ID: #{session.id}"
puts "  Workout: #{workout.name}"
puts "  Blocks: #{workout.blocks.size}"
puts "\nExpected Block Details:"
workout.blocks.each_with_index do |block, i|
  puts "  Block #{i+1}: #{block['type'].upcase} - #{block['target_params'].inspect}"
end
puts "\nNext Steps:"
puts "  1. Update API_URL in source/Main.mc if needed"
puts "  2. Compile: monkeyc -d d2delta -s --outdir bin source/Main.mc"
puts "  3. Simulator will launch"
puts "  4. Watch app should fetch and display this workout"
puts "\nFor offline testing, cache this data in StorageManager"
puts "="*60
