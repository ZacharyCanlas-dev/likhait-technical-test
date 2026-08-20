class Expense < ApplicationRecord
  # UTC offsets span UTC-12 to UTC+14, so a client's own calendar date is never more than
  # one day ahead of the server's.
  TIMEZONE_LEEWAY = 1.day

  belongs_to :category

  validates :date,
    comparison: { less_than_or_equal_to: -> { Date.current + TIMEZONE_LEEWAY }, message: "can't be in the future" },
    allow_nil: true
end
