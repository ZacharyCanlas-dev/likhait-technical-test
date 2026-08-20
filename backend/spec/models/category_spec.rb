require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "name" do
    it "is required" do
      category = Category.new(name: "")

      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("can't be blank")
    end

    it "is rejected when it is only whitespace" do
      category = Category.new(name: "   ")

      expect(category).not_to be_valid
    end

    it "has its surrounding whitespace removed" do
      category = Category.create!(name: "  Groceries  ")

      expect(category.name).to eq("Groceries")
    end

    it "has runs of whitespace collapsed" do
      category = Category.create!(name: "Ice  Cream")

      expect(category.name).to eq("Ice Cream")
    end

    # U+00A0 survives String#strip, so without collapsing it this is a second
    # category the unique index reads as a different string.
    it "is not made distinct by a non-breaking space" do
      Category.create!(name: "Groceries")

      expect(Category.new(name: "Groceries ")).not_to be_valid
    end

    it "must be unique" do
      Category.create!(name: "Groceries")
      duplicate = Category.new(name: "Groceries")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    # Case-insensitivity comes from the column's utf8mb4_0900_ai_ci collation, not
    # from the validation, so this fails if the schema changes and app/ does not.
    it "must be unique regardless of case" do
      Category.create!(name: "Groceries")

      expect(Category.new(name: "groceries")).not_to be_valid
    end

    it "must be unique regardless of surrounding whitespace" do
      Category.create!(name: "Groceries")

      expect(Category.new(name: " Groceries ")).not_to be_valid
    end

    it "accepts the full width of the column" do
      expect(Category.new(name: "a" * 100)).to be_valid
    end

    it "is rejected beyond the width of the column" do
      category = Category.new(name: "a" * 101)

      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("is too long (maximum is 100 characters)")
    end
  end

  describe "icon" do
    it "is optional" do
      expect(Category.new(name: "Groceries")).to be_valid
    end

    it "is stored when it is a single character" do
      category = Category.create!(name: "Groceries", icon: "🛒")

      expect(category.icon).to eq("🛒")
    end

    # Both of these are a base character plus U+FE0F. They are indistinguishable
    # from a one-character icon in a diff, and a check counting characters rather
    # than grapheme clusters would reject them.
    it "accepts an icon built from more than one codepoint" do
      expect(Category.new(name: "Shopping", icon: "🛍️")).to be_valid
      expect(Category.new(name: "Travel", icon: "✈️")).to be_valid
    end

    it "accepts an ordinary character" do
      expect(Category.new(name: "Groceries", icon: "G")).to be_valid
    end

    it "rejects more than one character" do
      category = Category.new(name: "Groceries", icon: "ab")

      expect(category).not_to be_valid
      expect(category.errors[:icon]).to include("must be a single character")
    end

    it "rejects more than one emoji" do
      expect(Category.new(name: "Groceries", icon: "🛒🍔")).not_to be_valid
    end

    # A zero-width space is one grapheme cluster and is neither stripped nor
    # blank, so a rule counting only clusters accepts an icon that renders as
    # nothing.
    it "rejects a character that renders as nothing" do
      expect(Category.new(name: "Groceries", icon: "​")).not_to be_valid
      expect(Category.new(name: "Groceries", icon: "️")).not_to be_valid
    end

    # One grapheme cluster, seventeen characters: a base letter and sixteen
    # combining accents. It passes the single-character rule, so only the length
    # validation rejects it.
    it "rejects a single character too long for the column" do
      category = Category.new(name: "Groceries", icon: "a" + "́" * 16)

      expect(category).not_to be_valid
      expect(category.errors[:icon]).to include("is too long (maximum is 16 characters)")
    end

    it "stores a blank icon as nothing rather than an empty string" do
      category = Category.create!(name: "Groceries", icon: "  ")

      expect(category.icon).to be_nil
    end
  end

  describe "expenses" do
    it "destroys its expenses when destroyed" do
      category = Category.create!(name: "Groceries")
      Expense.create!(description: "Lunch", amount: 10.00, category: category, date: Date.current)

      expect { category.destroy }.to change(Expense, :count).by(-1)
    end
  end
end
