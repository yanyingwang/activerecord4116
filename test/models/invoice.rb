class Invoice < ActiveRecord4116::Base
  has_many :line_items, :autosave => true
  before_save {|record| record.balance = record.line_items.map(&:amount).sum }
end
