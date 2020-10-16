class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.string :website_url
      t.string :short_url
      t.text :content

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end