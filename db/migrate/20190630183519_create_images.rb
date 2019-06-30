# Generates initial table for storing images
class CreateImages < ActiveRecord::Migration[5.2]
  def change
    create_table :images do |t|
      t.string :filename
      t.string :mime_type
      t.integer :size
      t.binary :data, null: false

      t.timestamps
    end
  end
end
