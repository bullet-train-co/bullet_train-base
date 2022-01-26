# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :slug
      t.boolean :being_destroyed, default: false
      t.string :time_zone
      t.string :locale

      t.timestamps
    end
  end
end
