FactoryBot.define do
  factory :category do
    # `name` carries a unique index, so a literal would make a second
    # create(:category) in one example raise.
    sequence(:name) { |n| "Category #{n}" }
  end
end
