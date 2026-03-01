class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :message, null: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :notifications, %i[user_id read]
  end
end

