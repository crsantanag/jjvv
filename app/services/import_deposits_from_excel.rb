# app/services/import_deposits_from_excel.rb
require "roo"

class ImportDepositsFromExcel
  attr_reader :successful, :failed, :errors

  def initialize(file, current_user)
    @file = file
    @current_user = current_user
    @successful = []
    @failed = []
    @errors = []
  end

  def call
    spreadsheet = Roo::Spreadsheet.open(@file.path)
    header = spreadsheet.row(1)

    (2..spreadsheet.last_row).each do |i|
      row = Hash[[ header, spreadsheet.row(i) ].transpose]

      apartment = @current_user.apartments.find_by(number: row["apartment_number"])
      if apartment.nil?
      tipo = @current_user.type_community.to_s.capitalize
        @failed << row
        @errors << { row: i, messages: [ "#{tipo} #{row['apartment_number']} no existe para este usuario." ] }
        next
      end

      base_date = row["date"].is_a?(Date) ? row["date"] : Date.parse(row["date"].to_s)
      tipo_ingreso = row["tipo_ingreso"].to_i
      amount = row["amount"].to_i
      original_comment = row["comment"].to_s


      if tipo_ingreso == 1

      mes_dep = row["mes"].to_i
      ano_dep = row["ano"].to_i
        deposit = Deposit.new(
          date: base_date,
          amount: amount,
          comment: original_comment,
          tipo_ingreso: tipo_ingreso,
          mes: mes_dep,
          ano: ano_dep,
          user_id: @current_user.id,
          apartment_id: apartment.id
        )

      else

        # Para tipo_ingreso distinto de 1, no se usa mes ni año
        deposit = Deposit.new(
          date: base_date,
          amount: amount,
          comment: original_comment,
          tipo_ingreso: tipo_ingreso,
          mes: nil,
          ano: nil,
          user_id: @current_user.id,
          apartment_id: apartment.id
        )
      end

      if deposit.save
        @successful << deposit
      else
        @failed << row
        @errors << { row: i, messages: deposit.errors.full_messages }
      end
    end

    self
  end
end
