import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../state/expenses_state.dart';

/// Add/edit form for a single expense.
///
/// Pass [existingExpense] to edit it (the form pre-fills and a delete action
/// becomes available); omit it to create a new one. The date picker defaults
/// to today and its `lastDate` is today, matching the backend's
/// `@PastOrPresent` validation on the expense date.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.existingExpense});

  final Expense? existingExpense;

  bool get isEditing => existingExpense != null;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    if (existing != null) {
      _categoryId = existing.categoryId;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _descriptionController.text = existing.description;
      _date = existing.date;
    }
    final expensesState = context.read<ExpensesState>();
    if (expensesState.categories.isEmpty) {
      expensesState.loadCategories();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      // Backend requires the date to be in the past or present, so the
      // picker can never offer a future date either.
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _errorMessage = 'Select a category.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final expense = Expense(
      id: widget.existingExpense?.id,
      categoryId: _categoryId!,
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      date: _date,
    );

    try {
      final saved = await context.read<ExpensesState>().submit(expense);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save the expense: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existingExpense?.id;
    if (id == null) return;
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    try {
      await context.read<ExpensesState>().delete(id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not delete the expense: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpensesState>().categories;
    final busy = _isSubmitting || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit expense' : 'Add expense'),
        actions: [
          if (widget.isEditing)
            IconButton(
              key: const Key('delete_expense_button'),
              icon: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              onPressed: busy ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                key: const Key('category_dropdown'),
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final Category category in categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('amount_field'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('description_field'),
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(Expense.formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    key: const Key('expense_form_error_text'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                key: const Key('submit_expense_button'),
                onPressed: busy ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Add expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
