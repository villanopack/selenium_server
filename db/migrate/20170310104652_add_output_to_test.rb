class AddOutputToTest < ActiveRecord::Migration[5.0]
  def change
    add_column :tests, :output, :text
  end
end
