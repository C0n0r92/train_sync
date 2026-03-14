class CreateQrScans < ActiveRecord::Migration[8.0]
  def change
    create_table :qr_scans do |t|
      t.references :qr_code, null: false, foreign_key: { to_table: :qr_codes }
      t.references :athlete, null: false, foreign_key: { to_table: :users }
      t.datetime :scanned_at

      t.timestamps
    end

    add_index :qr_scans, [:qr_code_id, :athlete_id], unique: true
  end
end
