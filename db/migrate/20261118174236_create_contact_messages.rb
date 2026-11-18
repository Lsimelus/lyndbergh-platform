# Messages people send me through a contact form (the Portfolio today). See docs/schemas.md.
class CreateContactMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_messages do |t|
      t.string :site, null: false, default: "portfolio"
      t.string :name, null: false
      t.string :email, null: false
      t.string :subject, null: false
      t.text :message, null: false
      t.timestamps
    end
    add_index :contact_messages, :created_at
  end
end
