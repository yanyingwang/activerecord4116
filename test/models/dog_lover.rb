class DogLover < ActiveRecord4116::Base
  has_many :trained_dogs, class_name: "Dog", foreign_key: :trainer_id, dependent: :destroy
  has_many :bred_dogs, class_name: "Dog", foreign_key: :breeder_id
  has_many :dogs
end
