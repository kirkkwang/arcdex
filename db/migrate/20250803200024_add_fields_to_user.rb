class AddFieldsToUser < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider
      t.string :uid
      t.string :avatar_url
    end
  end
end
