# Feedback from a product's feedback button: a 1-5 rating, a comment, or both. See docs/schemas.md.
class CreateFeedback < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback do |t|
      t.string :site, null: false
      t.integer :rating
      t.text :comment
      t.string :page
      t.string :user_ref # the site's own user id, so feedback can be deleted with the account
      t.string :email
      t.timestamps
    end
    add_index :feedback, %i[site created_at]
    add_index :feedback, %i[site user_ref]
  end
end
