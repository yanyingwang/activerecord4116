class PeopleHaveLastNames < ActiveRecord4116::Migration
  def self.up
    add_column "people", "hobbies", :string
  end

  def self.down
    remove_column "people", "hobbies"
  end
end
