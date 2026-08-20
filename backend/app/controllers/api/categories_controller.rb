class Api::CategoriesController < ApplicationController
  def index
    categories = Category.order(:name)
    render json: categories
  end

  def create
    category = Category.new(category_params)

    if save_category(category)
      render json: category, status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def save_category(category)
    category.save
  rescue ActiveRecord::RecordNotUnique
    # `name` carries the only unique index on the table.
    category.errors.add(:name, :taken)
    false
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
