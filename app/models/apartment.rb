class Apartment < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many   :deposits, dependent: :destroy

  validates :number, presence: true, uniqueness: true
end
