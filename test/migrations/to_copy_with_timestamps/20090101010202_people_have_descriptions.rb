class PeopleHaveLastNames < ActiveRecord4116::Migration
  def self.up
    add_column "people", "description", :text
  end

  def self.down
    remove_column "people", "description"
  end
end
