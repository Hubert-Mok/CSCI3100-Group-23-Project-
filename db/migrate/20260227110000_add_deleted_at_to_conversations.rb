class AddDeletedAtToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :buyer_deleted_at, :datetime
    add_column :conversations, :seller_deleted_at, :datetime
    add_index :conversations, :buyer_deleted_at
    add_index :conversations, :seller_deleted_at
  end
end
