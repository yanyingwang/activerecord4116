class MigrationVersionCheck < ActiveRecord4116::Migration
  def self.up
    raise "incorrect migration version" unless version == 20131219224947
  end

  def self.down
  end
end
