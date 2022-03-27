# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :time_zone
      t.datetime :last_seen_at
      t.string :profile_photo_id
      t.jsonb :ability_cache
      t.datetime :last_notification_email_sent_at
      t.boolean :former_user, default: false
      t.string :locale
      t.references :current_team, null: true, foreign_key: { to_table: :teams }
      # used for doorkeeper applications
      t.references :platform_agent_of, null: true, foreign_key: { to_table: :oauth_applications }

      t.timestamps
    end
  end
end
