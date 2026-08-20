class Expense < ApplicationRecord
  # UTC offsets span UTC-12 to UTC+14, so a client's own calendar date is never more than
  # one day ahead of the server's.
  TIMEZONE_LEEWAY = 1.day

  belongs_to :category

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :date, presence: true

  # `allow_nil` stays: ComparisonValidator answers a nil value with a :blank error and
  # merges this validation's :message into it, so a missing date would otherwise be
  # reported as "can't be in the future".
  validates :date,
    comparison: { less_than_or_equal_to: -> { Date.current + TIMEZONE_LEEWAY }, message: "can't be in the future" },
    allow_nil: true
end
