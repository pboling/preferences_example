class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.string :name, :null => false
      t.text :value
      t.string :description
      t.datetime :begin_at
      t.datetime :end_at
      t.boolean :enabled, :null => false, :default => false
      t.boolean :available, :null => false, :default => false
      t.integer :updated_by

      t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end
