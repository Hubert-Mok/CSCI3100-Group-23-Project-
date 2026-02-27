class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :product, null: false, foreign_key: true
      t.bigint :buyer_id, null: false
      t.bigint :seller_id, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [:product_id, :buyer_id], unique: true
    add_foreign_key :conversations, :users, column: :buyer_id
    add_foreign_key :conversations, :users, column: :seller_id
  end
end

