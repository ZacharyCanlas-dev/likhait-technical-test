class AddIconToCategories < ActiveRecord::Migration[7.2]
  # Declared here rather than using Category so this migration still runs after the
  # model is renamed or removed.
  class Category < ActiveRecord::Base
  end

  ICON_BY_NAME = {
    "Food" => "🍔",
    "Transportation" => "🚗",
    "Shopping" => "🛍️",
    "Entertainment" => "🎬",
    "Bills" => "📄",
    "Healthcare" => "🏥",
    "Education" => "📚",
    "Travel" => "✈️",
    "Personal" => "💆",
    "Other" => "📦"
  }.freeze

  def up
    # MySQL commits DDL immediately, so a backfill that raises leaves the column
    # added and the migration unrecorded. The guard lets the re-run get past it.
    add_column :categories, :icon, :string, limit: 16 unless column_exists?(:categories, :icon)

    ICON_BY_NAME.each do |name, icon|
      Category.where(name: name, icon: nil).update_all(icon: icon)
    end
  end

  def down
    remove_column :categories, :icon
  end
end
