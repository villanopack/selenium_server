class ChangeProductsToTests < ActiveRecord::Migration[5.0]
  def change
    rename_table :products, :tests
  end
end
