class AddKindToLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :logs, :kind, :integer, null:false, default: 0
  end
end
