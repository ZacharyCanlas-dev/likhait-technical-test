require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:category) { Category.create!(name: "Food") }

  def expense_dated(date)
    Expense.new(description: "Lunch", amount: 10.00, category: category, date: date)
  end

  it "has a factory that builds a valid record" do
    expect(build(:expense)).to be_valid
  end

  it "has a category factory that can be used twice in one example" do
    expect { create(:category) && create(:category) }.to change(Category, :count).by(2)
  end

  describe "associations" do
    it { is_expected.to belong_to(:category) }
  end

  describe "description" do
    it "rejects an empty string" do
      expense = build(:expense, description: "")

      expect(expense).not_to be_valid
      expect(expense.errors.full_messages).to include("Description can't be blank")
    end

    it "rejects whitespace only" do
      expect(build(:expense, description: "   ")).not_to be_valid
    end

    it "accepts any non-blank text" do
      expect(build(:expense, description: "Coffee")).to be_valid
    end
  end

  describe "amount" do
    it "rejects a negative amount" do
      expense = build(:expense, amount: -100.00)

      expect(expense).not_to be_valid
      expect(expense.errors.full_messages).to include("Amount must be greater than 0")
    end

    it "rejects zero" do
      expect(build(:expense, amount: 0)).not_to be_valid
    end

    it "rejects a missing amount rather than leaving it to the database" do
      expect(build(:expense, amount: nil)).not_to be_valid
    end

    it "accepts a positive amount" do
      expect(build(:expense, amount: 0.01)).to be_valid
    end
  end

  describe "date" do
    # The examples name dates relative to Date.current, and the validator reads it again
    # a moment later.
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
