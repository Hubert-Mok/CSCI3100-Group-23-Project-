# frozen_string_literal: true

class AllowNullBodyOnMessages < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :body, true
  end
end
