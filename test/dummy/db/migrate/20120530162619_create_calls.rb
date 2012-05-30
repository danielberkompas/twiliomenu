class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.string :current_menu

      t.timestamps
    end
  end
end
