class CreateChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :checks do |t|
      t.string :site_slug, null: false
      t.boolean :ok, null: false
      t.integer :http_status
      t.integer :latency_ms
      t.string :error

      t.timestamps
    end
    add_index :checks, :site_slug
  end
end
