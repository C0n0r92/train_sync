class CreateWorkoutSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_sessions do |t|
      t.references :qr_scan, null: false, foreign_key: { to_table: :qr_scans }
      t.references :athlete, null: false, foreign_key: { to_table: :users }
      t.references :workout, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :workout_sessions, :completed_at
  end
end
