class Expense < ApplicationRecord
  belongs_to :category

  # `id` is a tiebreaker, not decoration: expenses routinely share a date, and
  # SQL leaves the order of tied rows unspecified without a unique column.
  scope :ordered_by_date, -> { order(date: :desc, id: :desc) }

  scope :in_month, ->(year, month) { where(date: Date.new(year, month, 1).all_month) }
end
