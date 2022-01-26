# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :uuid
      t.references :from_membership, null: false, foreign_key: { to_table: :memberships }
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
