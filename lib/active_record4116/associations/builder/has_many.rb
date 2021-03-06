module ActiveRecord4116::Associations::Builder
  class HasMany < CollectionAssociation #:nodoc:
    def macro
      :has_many
    end

    def valid_options
      super + [:primary_key, :dependent, :as, :through, :source, :source_type, :inverse_of, :counter_cache, :join_table]
    end

    def self.valid_dependent_options
      [:destroy, :delete_all, :nullify, :restrict_with_error, :restrict_with_exception]
    end
  end
end
