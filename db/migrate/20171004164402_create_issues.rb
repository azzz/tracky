class CreateIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :issues do |t|
      t.references :author, null: false
      t.references :assignee
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
  end
end
