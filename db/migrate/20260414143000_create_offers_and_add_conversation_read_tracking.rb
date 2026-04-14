class CreateOffersAndAddConversationReadTracking < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :buyer_last_read_message_at, :datetime
    add_column :conversations, :seller_last_read_message_at, :datetime

    create_table :offers do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.references :proposed_by, null: false, foreign_key: { to_table: :users }
      t.references :parent_offer, foreign_key: { to_table: :offers }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :offers, [ :conversation_id, :created_at ]
    add_index :offers, [ :conversation_id, :status ]
  end
end
