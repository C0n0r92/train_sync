class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.references :coach, null: false, foreign_key: { to_table: :users }
      t.string :name
      t.jsonb :blocks
      t.integer :status, default: 0
      t.integer :version, default: 1
      t.boolean :is_public, default: false

      t.timestamps
    end

    add_index :workouts, :status
  end
end
