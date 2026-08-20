import React, { useState, useEffect } from "react";
import { getExpenses, createExpense } from "../services/api";
import { Expense, ExpenseFormData } from "../types";
import YearNavigation from "../components/YearNavigation";
import { MonthNavigation } from "../components/MonthNavigation";
import CategoryBreakdown from "../components/CategoryBreakdown";
import { CalendarExpenseTable } from "../components/CalendarExpenseTable";
import { ExpenseForm } from "../components/ExpenseForm";
import { CategoryForm } from "../components/CategoryForm";
import { useCategories } from "../hooks/useCategories";
import { Modal, Button } from "../vibes";
import { COLORS } from "../constants/colors";

function addExpenseBlockedReason(
  isLoading: boolean,
  error: string | null,
  categoryCount: number,
): string | undefined {
  if (isLoading) return "Loading categories...";
  if (error) return error;
  if (categoryCount === 0) {
    return "Add a category before recording an expense.";
  }
  return undefined;
}

const HistoryPage: React.FC = () => {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const {
    categories: categories,
    isLoading: categoriesLoading,
    error: categoriesError,
    addCategory,
    reload: reloadCategories,
  } = useCategories();

  // Get year and month from URL params, default to current date if not provided
  const getInitialYearMonth = () => {
    const params = new URLSearchParams(window.location.search);
    const currentDate = new Date();
    const yearParam = params.get("year");
    const monthParam = params.get("month");

    return {
      year: yearParam ? parseInt(yearParam) : currentDate.getFullYear(),
      month: monthParam ? parseInt(monthParam) : currentDate.getMonth() + 1,
    };
  };

  const initial = getInitialYearMonth();
  const [selectedYear, setSelectedYear] = useState(initial.year);
  const [selectedMonth, setSelectedMonth] = useState(initial.month);

  // Update URL when year or month changes
  const updateURL = (year: number, month: number) => {
    const params = new URLSearchParams();
    params.set("year", year.toString());
    params.set("month", month.toString());
    const newURL = `${window.location.pathname}?${params.toString()}`;
    window.history.pushState({}, "", newURL);
  };

  // Initialize URL params if not present
  useEffect(() => {
    updateURL(selectedYear, selectedMonth);
  }, []);

  useEffect(() => {
    fetchExpenses();
  }, [selectedYear, selectedMonth]);

  const fetchExpenses = async () => {
    try {
      setLoading(true);
      const data = await getExpenses(selectedYear, selectedMonth);
      setExpenses(data);
    } catch (error) {
      console.error("Error fetching expenses:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleYearChange = (year: number) => {
    setSelectedYear(year);
    updateURL(year, selectedMonth);
  };

  const handleMonthChange = (month: number) => {
    setSelectedMonth(month);
    updateURL(selectedYear, month);
  };

  const handleAddExpense = async (data: ExpenseFormData) => {
    try {
      await createExpense(data);
      setIsModalOpen(false);
      fetchExpenses();
    } catch (error) {
      console.error("Error creating expense:", error);
      throw error;
    }
  };

  // Calculate category breakdown
  const categoryData = expenses.reduce(
    (acc, expense) => {
      const category = expense.category || "Uncategorized";
      if (!acc[category]) {
        acc[category] = {
          category,
          icon:
            categories.find((entry) => entry.name === category)?.icon ?? null,
          amount: 0,
          count: 0,
        };
      }
      acc[category].amount += Number(expense.amount);
      acc[category].count += 1;
      return acc;
    },
    {} as Record<
      string,
      { category: string; icon: string | null; amount: number; count: number }
    >,
  );

  const categoryTotals = Object.values(categoryData).sort(
    (a, b) => b.amount - a.amount,
  );
  const total = categoryTotals.reduce((sum, cat) => sum + cat.amount, 0);
  const totalCount = categoryTotals.reduce((sum, cat) => sum + cat.count, 0);

  const blockedReason = addExpenseBlockedReason(
    categoriesLoading,
    categoriesError,
    categories.length,
  );

  const pageStyle: React.CSSProperties = {
    padding: "48px 64px",
    minHeight: "100vh",
    background: COLORS.secondary.s01,
  };

  const headerStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: "24px",
    justifyContent: "space-between",
  };

  const leftHeaderStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: "24px",
  };

  const headerActionsStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    flexShrink: 0,
  };

  const bannerStyle = (isError: boolean): React.CSSProperties => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: "16px",
    marginTop: "16px",
    padding: "12px 16px",
    borderRadius: "0.375rem",
    border: `1px solid ${isError ? COLORS.red.re04 : COLORS.border}`,
    backgroundColor: isError ? COLORS.red.re02 : COLORS.background.card,
    color: isError ? COLORS.red.re07 : COLORS.text.secondary,
    fontSize: "14px",
  });

  const titleStyle: React.CSSProperties = {
    fontSize: "40px",
    fontWeight: 700,
    color: COLORS.secondary.s10,
    margin: 0,
    flexShrink: 0,
  };

  const loadingStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "48px",
    fontSize: "18px",
    color: COLORS.secondary.s08,
  };

  return (
    <div style={pageStyle}>
      <div style={headerStyle}>
        <div style={leftHeaderStyle}>
          <h1 style={titleStyle}>Expense History</h1>
          <YearNavigation
            currentYear={selectedYear}
            onYearChange={handleYearChange}
          />
        </div>
        <div style={headerActionsStyle}>
          <Button
            variant="secondary"
            onClick={() => setIsCategoryModalOpen(true)}
          >
            Add Category
          </Button>
          <Button
            variant="primary"
            onClick={() => setIsModalOpen(true)}
            disabled={Boolean(blockedReason)}
          >
            Add Expense
          </Button>
        </div>
      </div>

      {blockedReason && (
        <div
          style={bannerStyle(Boolean(categoriesError))}
          role={categoriesError ? "alert" : undefined}
        >
          <span>{blockedReason}</span>
          {categoriesError && (
            <Button variant="secondary" size="small" onClick={reloadCategories}>
              Retry
            </Button>
          )}
        </div>
      )}

      <MonthNavigation
        currentMonth={selectedMonth}
        currentYear={selectedYear}
        onMonthChange={handleMonthChange}
      />

      <div>
        {loading ? (
          <div style={loadingStyle}>Loading...</div>
        ) : (
          <>
            <CategoryBreakdown
              categories={categoryTotals}
              total={total}
              totalCount={totalCount}
            />
            <div style={{ marginTop: "32px" }}>
              <CalendarExpenseTable
                expenses={expenses}
                categories={categories}
                onExpenseUpdated={fetchExpenses}
              />
            </div>
          </>
        )}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Add New Expense"
      >
        <ExpenseForm
          categories={categories}
          onSubmit={handleAddExpense}
          onCancel={() => setIsModalOpen(false)}
        />
      </Modal>

      <Modal
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
        title="Add Category"
      >
        <CategoryForm
          categories={categories}
          isLoading={categoriesLoading}
          loadError={categoriesError}
          onSubmit={addCategory}
          onDone={() => setIsCategoryModalOpen(false)}
        />
      </Modal>
    </div>
  );
};

export default HistoryPage;
