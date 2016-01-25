class AddApprovedToFriend < ActiveRecord::Migration
  def change
    add_column :friends, :approved, :boolean
  end
end
