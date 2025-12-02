class Bill < ApplicationRecord
  belongs_to :user

  validates :amount, numericality: { only_integer: true, other_than: 0 }

  enum :tipo_egreso,
        [ :egreso_default,
          :egreso_1,
          :egreso_2,
          :egreso_3,
          :egreso_4,
          :egreso_5 ]
end
