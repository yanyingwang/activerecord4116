class WithoutTable < ActiveRecord4116::Base
  default_scope -> { where(:published => true) }
end
