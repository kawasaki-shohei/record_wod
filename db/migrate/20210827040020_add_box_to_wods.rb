class AddBoxToWods < ActiveRecord::Migration[6.1]
  def change
    add_column :wods, :box, :integer, null: false, default: 0
  end
end
