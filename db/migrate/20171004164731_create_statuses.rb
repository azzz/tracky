class CreateStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :statuses do |t|
      t.string :name, null: false
      t.references :issue, null: false

      t.timestamps
    end
  end
end
