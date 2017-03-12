class AddAasmStateToTest < ActiveRecord::Migration[5.0]
  def change
    add_column :tests, :aasm_state, :string
  end
end
