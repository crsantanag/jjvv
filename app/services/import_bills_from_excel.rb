require "roo"

class ImportBillsFromExcel
  attr_reader :successful, :failed, :errors

  def initialize(file)
    @file = file
    @successful = []
    @failed = []
    @errors = []
  end

  def call
    spreadsheet = Roo::Spreadsheet.open(@file.path)
    header = spreadsheet.row(1)

    (2..spreadsheet.last_row).each do |i|
      row = Hash[[ header, spreadsheet.row(i) ].transpose]

      bill = Bill.new(
        date: row["date"],
        tipo_egreso: row["tipo_egreso"],
        comment: row["comment"],
        amount: row["amount"],
        user_id: row["user_id"]
      )

      if bill.valid?
         bill.save
         @successful << bill
      else
         @failed << row
         @errors << { row: i, messages: bill.errors.full_messages }
      end
    end

    self
  end
end
