# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_14_000517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.integer "platform", default: 0
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "qr_codes", force: :cascade do |t|
    t.bigint "workout_id", null: false
    t.string "short_id", null: false
    t.integer "variant", default: 0
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["short_id"], name: "index_qr_codes_on_short_id", unique: true
    t.index ["workout_id"], name: "index_qr_codes_on_workout_id"
  end

  create_table "qr_scans", force: :cascade do |t|
    t.bigint "qr_code_id", null: false
    t.bigint "athlete_id", null: false
    t.datetime "scanned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["athlete_id"], name: "index_qr_scans_on_athlete_id"
    t.index ["qr_code_id", "athlete_id"], name: "index_qr_scans_on_qr_code_id_and_athlete_id", unique: true
    t.index ["qr_code_id"], name: "index_qr_scans_on_qr_code_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workout_results", force: :cascade do |t|
    t.bigint "workout_session_id", null: false
    t.jsonb "block_results"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_session_id"], name: "index_workout_results_on_workout_session_id"
  end

  create_table "workout_sessions", force: :cascade do |t|
    t.bigint "qr_scan_id", null: false
    t.bigint "athlete_id", null: false
    t.bigint "workout_id", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["athlete_id"], name: "index_workout_sessions_on_athlete_id"
    t.index ["completed_at"], name: "index_workout_sessions_on_completed_at"
    t.index ["qr_scan_id"], name: "index_workout_sessions_on_qr_scan_id"
    t.index ["workout_id"], name: "index_workout_sessions_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.string "name"
    t.jsonb "blocks"
    t.integer "status", default: 0
    t.integer "version", default: 1
    t.boolean "is_public", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id"], name: "index_workouts_on_coach_id"
    t.index ["status"], name: "index_workouts_on_status"
  end

  add_foreign_key "device_tokens", "users"
  add_foreign_key "qr_codes", "workouts"
  add_foreign_key "qr_scans", "qr_codes"
  add_foreign_key "qr_scans", "users", column: "athlete_id"
  add_foreign_key "workout_results", "workout_sessions"
  add_foreign_key "workout_sessions", "qr_scans"
  add_foreign_key "workout_sessions", "users", column: "athlete_id"
  add_foreign_key "workout_sessions", "workouts"
  add_foreign_key "workouts", "users", column: "coach_id"
end
