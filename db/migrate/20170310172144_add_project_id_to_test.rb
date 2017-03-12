class AddProjectIdToTest < ActiveRecord::Migration[5.0]
  def change
    add_column :tests, :project_id, :integer
  end
end
