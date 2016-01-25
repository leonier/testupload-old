class CreateFriends < ActiveRecord::Migration
  def change
    create_table :friends do |t|
      t.references :source
      t.references :target

      t.timestamps
    end
    add_index :friends, :source_id
    add_index :friends, :target_id
  end
end
