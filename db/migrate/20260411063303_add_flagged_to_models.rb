class AddFlaggedToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :flagged, :boolean, default: false
    add_column :products, :flagged, :boolean, default: false
  end
end
