# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.string :user_first_name
      t.string :user_last_name
      t.string :user_profile_photo_id
      t.string :user_email
      t.jsonb :role_ids, default: []
      t.references :added_by, null: true, foreign_key: { to_table: :memberships }
      t.references :user, null: true, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :invitation, null: true, foreign_key: true
      # used for doorkeeper applications
      t.references :platform_agent_of, null: true, foreign_key: { to_table: "oauth_applications" }

      t.timestamps
    end
  end
end
