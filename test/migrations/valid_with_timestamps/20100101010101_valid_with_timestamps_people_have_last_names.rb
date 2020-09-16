class ValidWithTimestampsPeopleHaveLastNames < ActiveRecord4116::Migration
  def self.up
    add_column "people", "last_name", :string
  end

  def self.down
    remove_column "people", "last_name"
  end
end
