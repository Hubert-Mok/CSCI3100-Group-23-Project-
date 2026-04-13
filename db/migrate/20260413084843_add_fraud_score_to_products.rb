class AddFraudScoreToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :fraud_score, :float
  end
end
