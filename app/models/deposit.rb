class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :apartment

  # attr_accessor :apartment_number  # campo virtual para el formulario

  enum :tipo_ingreso,
        [ :ingreso_default,
          :ingreso_1,
          :ingreso_2,
          :ingreso_3,
          :ingreso_4,
          :ingreso_5 ]

  # before_validation :assign_apartment_by_number
  before_validation :set_month_and_year_from_date, if: -> { tipo_ingreso != "ingreso_comun" }

  # validate :apartment_number_must_exist

  validates :mes, :ano, presence: true, if: -> { tipo_ingreso == "ingreso_comun" }

  validates :amount, numericality: { only_integer: true, other_than: 0 }

  MONTHS = [
    [ "Enero", 1 ],
    [ "Febrero", 2 ],
    [ "Marzo", 3 ],
    [ "Abril", 4 ],
    [ "Mayo",  5 ],
    [ "Junio", 6 ],
    [ "Julio", 7 ],
    [ "Agosto",  8 ],
    [ "Septiembre", 9 ],
    [ "Octubre", 10 ],
    [ "Noviembre", 11 ],
    [ "Diciembre", 12 ] ]

  YEARS  = [ [ "2025", 2025 ], [ "2024", 2024 ], [ "2023", 2023 ], [ "2022", 2022 ], [ "2021",  2021 ], [ "2020", 2020 ] ]

  private

  #  def assign_apartment_by_number
  #    return if apartment_number.blank?
  #    self.apartment = Apartment.find_by(number: apartment_number)
  #  end

  #  def apartment_number_must_exist
  #    if apartment_number.present? && self.apartment.nil?
  #        errors.add(:apartment_number, "no corresponde a ningún socio")
  #    end
  #  end

  def set_month_and_year_from_date
    if date.present?
      self.mes = date.month
      self.ano = date.year
    end
  end
end
