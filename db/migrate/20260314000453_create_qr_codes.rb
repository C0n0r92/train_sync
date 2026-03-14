class CreateQrCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :qr_codes do |t|
      t.references :workout, null: false, foreign_key: true
      t.string :short_id, null: false
      t.integer :variant, default: 0
      t.datetime :expires_at

      t.timestamps
    end

    add_index :qr_codes, :short_id, unique: true
  end
end
