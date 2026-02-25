class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :cuhk_id, null: false
      t.string :username, null: false
      t.string :college_affiliation, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
