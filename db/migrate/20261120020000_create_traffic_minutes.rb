class CreateTrafficMinutes < ActiveRecord::Migration[8.1]
  def change
    # Per site, per minute totals of the requests kamal-proxy served (script/traffic-collector). Counts only:
    # no IPs, user agents or paths.
    create_table :traffic_minutes do |t|
      t.string :site_slug, null: false
      t.datetime :minute, null: false
      t.integer :requests, null: false, default: 0
      t.integer :errors_4xx, null: false, default: 0
      t.integer :errors_5xx, null: false, default: 0
      t.float :total_ms, null: false, default: 0
      t.float :max_ms, null: false, default: 0
    end
    add_index :traffic_minutes, %i[site_slug minute], unique: true
    add_index :traffic_minutes, :minute
  end
end
