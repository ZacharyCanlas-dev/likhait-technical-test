class Api::ExpensesController < ApplicationController
  MAX_PAGE_SIZE = 500

  def index
    expenses = Expense.includes(:category).ordered_by_date

    if params[:year].present? && params[:month].present?
      year = integer_param(:year)
      month = integer_param(:month)

      unless year && month && Date.valid_date?(year, month, 1)
        return render json: { errors: [ "year and month must form a valid month" ] },
                      status: :bad_request
      end

      expenses = expenses.in_month(year, month)
    end

    response.set_header("X-Total-Count", expenses.count.to_s)
    page = expenses.limit(page_size).offset(page_offset)

    render json: page.map { |expense| format_expense(expense) }
  end

  def create
    expense = Expense.new(expense_params)

    if expense.save
      render json: format_expense(expense), status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    expense = Expense.find(params[:id])

    if expense.update(expense_params)
      render json: format_expense(expense)
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    head :no_content
  end

  private

  # `to_i` maps "abc" to 0 and "13abc" to 13, either of which would reach
  # Date.valid_date? as a plausible-looking number.
  def integer_param(name)
    value = params[name].to_s
    value.match?(/\A-?\d+\z/) ? value.to_i : nil
  end

  def page_size
    requested = integer_param(:limit)
    return MAX_PAGE_SIZE unless requested&.positive?

    [ requested, MAX_PAGE_SIZE ].min
  end

  def page_offset
    offset = integer_param(:offset)
    offset&.positive? ? offset : 0
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :category_id, :date)
  end

  def format_expense(expense)
    {
      id: expense.id,
      description: expense.description,
      amount: expense.amount.to_f,
      category: expense.category.name,
      date: expense.date.to_s,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }
  end
end
