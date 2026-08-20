/**
 * Custom hook for managing expense form state and validation
 */

import { useState } from "react";
import { ExpenseFormData } from "../types";
import { isFutureDate, today } from "../utils/expenseUtils";
import { ApiError } from "../services/api";

const FUTURE_DATE_ERROR = "Expenses can only be dated today or earlier";

interface UseExpenseFormProps {
  initialData?: Partial<ExpenseFormData>;
  onSubmit: (data: ExpenseFormData) => Promise<void>;
}

export function useExpenseForm({ initialData, onSubmit }: UseExpenseFormProps) {
  const [formData, setFormData] = useState<ExpenseFormData>({
    amount: initialData?.amount || "",
    description: initialData?.description || "",
    category: initialData?.category || "",
    date: initialData?.date || today(),
  });

  // An expense already stored with a future date opens the edit form in breach, and
  // nothing would say so until the user pressed Update.
  const [errors, setErrors] = useState<Partial<ExpenseFormData>>(() =>
    isFutureDate(formData.date) ? { date: FUTURE_DATE_ERROR } : {},
  );
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (field: keyof ExpenseFormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setSubmitError(null);

    // A date input emits either a complete date or nothing, so it can be judged as
    // it changes. The others would fault a value the user is still typing.
    if (field === "date") {
      setErrors((prev) => ({
        ...prev,
        date: isFutureDate(value) ? FUTURE_DATE_ERROR : undefined,
      }));
      return;
    }

    // Clear error for this field when user starts typing
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Partial<ExpenseFormData> = {};

    if (!formData.amount || Number(formData.amount) <= 0) {
      newErrors.amount = "Amount must be greater than 0";
    }

    if (!formData.description.trim()) {
      newErrors.description = "Description is required";
    }

    if (!formData.category) {
      newErrors.category = "Category is required";
    }

    if (!formData.date) {
      newErrors.date = "Date is required";
    } else if (isFutureDate(formData.date)) {
      newErrors.date = FUTURE_DATE_ERROR;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setSubmitError(null);

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(formData);
      // Reset form on success
      setFormData({
        amount: "",
        description: "",
        category: "",
        date: today(),
      });
      setErrors({});
    } catch (error) {
      setSubmitError(
        error instanceof ApiError
          ? error.message
          : "The expense could not be saved. Please try again.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      amount: initialData?.amount || "",
      description: initialData?.description || "",
      category: initialData?.category || "",
      date: initialData?.date || today(),
    });
    setErrors({});
    setSubmitError(null);
  };

  return {
    formData,
    errors,
    submitError,
    isSubmitting,
    handleChange,
    handleSubmit,
    resetForm,
  };
}
