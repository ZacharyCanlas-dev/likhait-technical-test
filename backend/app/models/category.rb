class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  # Collapsed as well as stripped: `strip` leaves U+00A0 in place, so without this
  # "Groceries " is a second category the unique index cannot tell from the first.
  normalizes :name, with: ->(name) { name.gsub(/[[:space:]]+/, " ").strip }
  normalizes :icon, with: ->(icon) { icon.strip.presence }

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }

  validates :icon, length: { maximum: 16 }
  validate :icon_must_be_a_single_grapheme

  private

  def icon_must_be_a_single_grapheme
    return if icon.blank?
    # A cluster made only of marks, format or separator characters is one cluster
    # wide and renders as nothing, so a zero-width space would otherwise pass as a
    # visible icon. Emoji keep their U+FE0F and ZWJ because the rule asks for one
    # character that is none of those, not for every character to qualify.
    return if icon.grapheme_clusters.size == 1 && icon.match?(/[^\p{C}\p{Z}\p{M}]/)

    errors.add(:icon, "must be a single character")
  end
end
