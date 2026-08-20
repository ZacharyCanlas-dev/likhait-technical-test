class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  # Collapsed as well as stripped: `strip` leaves U+00A0 in place, so without this
  # "Groceries " is a second category the unique index cannot tell from the first.
  normalizes :name, with: ->(name) { name.gsub(/[[:space:]]+/, " ").strip }

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
end
