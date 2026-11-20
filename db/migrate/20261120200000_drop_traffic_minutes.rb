# /traffic is gone: New Relic now has requests, errors and latency for the apps on the server.
class DropTrafficMinutes < ActiveRecord::Migration[8.1]
  def change
    drop_table :traffic_minutes do |t|
      t.string :site_slug, null: false
      t.datetime :minute, null: false
      t.integer :requests, null: false, default: 0
      t.integer :errors_4xx, null: false, default: 0
      t.integer :errors_5xx, null: false, default: 0
      t.float :total_ms, null: false, default: 0
      t.float :max_ms, null: false, default: 0
      t.index %i[site_slug minute], unique: true
      t.index :minute
    end
  end
end
