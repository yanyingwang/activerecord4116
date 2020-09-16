module Shop
  class Collection < ActiveRecord4116::Base
    has_many :products, :dependent => :nullify
  end

  class Product < ActiveRecord4116::Base
    has_many :variants, :dependent => :delete_all
    belongs_to :type

    class Type < ActiveRecord4116::Base
      has_many :products
    end
  end

  class Variant < ActiveRecord4116::Base
  end
end
