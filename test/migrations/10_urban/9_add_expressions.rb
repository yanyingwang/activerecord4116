class AddExpressions < ActiveRecord4116::Migration
  def self.up
    create_table("expressions") do |t|
      t.column :expression, :string
    end
  end

  def self.down
    drop_table "expressions"
  end
end
