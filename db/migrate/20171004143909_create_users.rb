class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :full_name, null: false
      t.string :role, null: false, default: 'client'

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
