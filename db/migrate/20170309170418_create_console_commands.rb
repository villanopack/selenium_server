class CreateConsoleCommands < ActiveRecord::Migration[5.0]
  def change
    create_table :console_commands do |t|
      t.string :name
      t.string :command
      t.string :status
      t.string :status

      t.timestamps
    end
  end
end
