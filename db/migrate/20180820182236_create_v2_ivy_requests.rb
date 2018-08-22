class CreateV2IvyRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :ivy_requests do |t|
      t.string :user_id
      t.string :library
      t.string :state
      t.string :catalog_id
      t.string :title
      t.string :volume
      t.string :edition
      t.string :author
      t.json :items

      t.timestamps
    end
  end
end
