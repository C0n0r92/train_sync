class CreateWorkoutResults < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_results do |t|
      t.references :workout_session, null: false, foreign_key: true
      t.jsonb :block_results
      t.datetime :completed_at

      t.timestamps
    end
  end
end
