class AddBasePathToProject < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :base_path, :string
  end
end
