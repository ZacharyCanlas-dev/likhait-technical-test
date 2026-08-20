require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:category) { Category.create!(name: "Food") }

  def expense_dated(date)
    Expense.new(description: "Lunch", amount: 10.00, category: category, date: date)
  end

  describe "date" do
    # Every example reads Date.current, and so does the validator a moment later.
    before { freeze_time }

    it "accepts a past date" do
      expect(expense_dated(Date.current - 1)).to be_valid
    end

    it "accepts today" do
      expect(expense_dated(Date.current)).to be_valid
    end

    it "accepts one day ahead, which is still today for a client east of UTC" do
      expect(expense_dated(Date.current + 1)).to be_valid
    end

    it "rejects two days ahead, which is the future in every timezone" do
      expense = expense_dated(Date.current + 2)

      expect(expense).not_to be_valid
      expect(expense.errors.full_messages).to include("Date can't be in the future")
    end

    it "compares against the clock at validation time, not at boot" do
      expense = expense_dated(Date.current + 2)
      expect(expense).not_to be_valid

      travel_to(Date.current + 3) do
        expect(expense).to be_valid
      end
    end

    it "leaves a missing date to the database constraint" do
      expense = expense_dated(nil)

      expect(expense).to be_valid
      expect { expense.save! }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
