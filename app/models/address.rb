class Address < ApplicationRecord
  belongs_to :user
  has_many :apartments, dependent: :destroy

  # geocoder
  geocoded_by :street
  # solo geocodificar cuando cambie la calle o esté vacío lat/lng
  after_validation :geocode, if: ->(obj) { obj.street.present? && (obj.latitude.blank? || obj.longitude.blank? || obj.street_changed?) }

  # Validaciones opcionales
  validates :street, presence: true
end
