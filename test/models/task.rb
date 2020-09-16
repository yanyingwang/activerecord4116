class Task < ActiveRecord4116::Base
  def updated_at
    ending
  end
end
