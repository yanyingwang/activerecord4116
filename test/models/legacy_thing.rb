class LegacyThing < ActiveRecord4116::Base
  self.locking_column = :version
end
