class AddBookmarkOrderToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bookmark_order, :text
  end
end
