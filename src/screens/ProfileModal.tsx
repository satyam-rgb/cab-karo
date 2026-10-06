import React, { useState } from 'react';
import {
  X,
  User,
  Wallet,
  TrendingUp,
  PiggyBank,
  Plus,
  Trash2,
  Save,
  LogOut,
  Zap,
  Scale,
  Armchair,
  CheckCircle2,
  Calendar,
  AlertCircle
} from 'lucide-react';
import { storageService } from '../services/storageService';
import { Expense, ScoreMode } from '../types';

interface ProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLogout: () => void;
}

export const ProfileModal: React.FC<ProfileModalProps> = ({
  isOpen,
  onClose,
  onLogout
}) => {
  const [profile, setProfile] = useState(() => storageService.getUserProfile());
  const [budgetInput, setBudgetInput] = useState<string>(() =>
    profile?.monthlyBudget ? profile.monthlyBudget.toString() : '4500'
  );
  const [mode, setMode] = useState<ScoreMode>(() =>
    profile?.preferences?.mode || 'balanced'
  );
  const [comfortMode, setComfortMode] = useState<boolean>(() =>
    profile?.preferences?.comfort || false
  );
  const [expenses, setExpenses] = useState<Expense[]>(() =>
    storageService.getExpenses()
  );

  const [isAddExpenseOpen, setIsAddExpenseOpen] = useState(false);
  const [addProvider, setAddProvider] = useState('Uber');
  const [addCategory, setAddCategory] = useState('Cab');
  const [addAmount, setAddAmount] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [expenseError, setExpenseError] = useState('');

  if (!isOpen) return null;

  const currentBudget = parseFloat(budgetInput) || 0;
  const totalSpent = expenses.reduce((acc, curr) => acc + curr.amount, 0);
  const remaining = Math.max(0, currentBudget - totalSpent);
  const progressPercent = currentBudget > 0 ? Math.min(100, (totalSpent / currentBudget) * 100) : 0;
  const isOverBudget = currentBudget > 0 && totalSpent > currentBudget;

  const now = new Date();
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const daysRemaining = Math.max(1, daysInMonth - now.getDate() + 1);
  const averagePerDay = daysRemaining > 0 ? remaining / daysRemaining : 0;

  const handleSavePreferences = (e: React.FormEvent) => {
    e.preventDefault();
    const updated = storageService.saveUserProfile({
      monthlyBudget: currentBudget,
      preferences: {
        mode,
        comfort: comfortMode
      }
    });
    setProfile(updated);
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 2000);
  };

  const handleAddExpense = (e: React.FormEvent) => {
    e.preventDefault();
    const amt = parseFloat(addAmount);
    if (isNaN(amt) || amt <= 0) {
      setExpenseError('Please enter a valid expense amount.');
      return;
    }

    const newExpense = storageService.addExpense({
      provider: addProvider,
      category: addCategory,
      amount: amt,
      type: 'ride'
    });
    setExpenses([newExpense, ...expenses]);
    setAddAmount('');
    setExpenseError('');
    setIsAddExpenseOpen(false);
  };

  const handleDeleteExpense = (id: string) => {
    const updated = storageService.deleteExpense(id);
    setExpenses(updated);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-lg flex-col rounded-[28px] bg-[#F6F8FC] shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-200 bg-white p-5 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 shadow-xs">
              <User className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-black text-gray-950">My Profile & Budget</h3>
              <p className="text-xs text-gray-500 font-medium">
                Preferences and monthly transport tracking
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-full p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Scrollable Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-6">
          {/* User ID Profile Card */}
          <div className="rounded-[24px] bg-gradient-to-r from-blue-600 to-indigo-600 p-5 text-white shadow-lg shadow-blue-500/15">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3.5">
                <div className="flex h-13 w-13 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-xs text-white">
                  <User className="h-6 w-6" />
                </div>
                <div>
                  <h4 className="text-base font-extrabold">KaroCab Member</h4>
                  <p className="text-xs text-blue-100 font-semibold mt-0.5">
                    {profile?.phone || '+91 98765 43210'}
                  </p>
                </div>
              </div>
              <span className="rounded-full bg-white/20 px-3 py-1 text-[10px] font-black uppercase tracking-wider text-white">
                Active Session
              </span>
            </div>
          </div>

          {/* Monthly Transport Budget Dashboard */}
          <div>
            <h4 className="text-sm font-extrabold text-gray-950 mb-3 flex items-center gap-2">
              <Calendar className="h-4 w-4 text-blue-600" />
              <span>Current Month Budget Overview</span>
            </h4>
            <div className="rounded-2xl border border-gray-200 bg-white p-5 shadow-xs">
              <div className="flex items-center justify-between mb-3.5">
                <div className="flex items-center gap-2">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                    <Wallet className="h-4 w-4" />
                  </div>
                  <div>
                    <h5 className="text-sm font-bold text-gray-900">Mobility Allowance</h5>
                    <span className="text-[11px] text-gray-400 font-medium">Monthly Target</span>
                  </div>
                </div>
                <span className="text-xs font-black text-gray-800">
                  {progressPercent.toFixed(0)}% Utilized
                </span>
              </div>

              {/* Progress Bar */}
              <div className="h-2.5 w-full rounded-full bg-gray-100 overflow-hidden mb-4">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${
                    isOverBudget ? 'bg-red-500' : 'bg-blue-600'
                  }`}
                  style={{ width: `${progressPercent}%` }}
                />
              </div>

              {/* 3 Stats Grid */}
              <div className="grid grid-cols-3 gap-2 border-t border-gray-100 pt-3 text-center">
                <div>
                  <div className="flex justify-center text-gray-400 mb-1">
                    <Wallet className="h-4 w-4" />
                  </div>
                  <div className="text-sm font-extrabold text-gray-900">
                    ₹{currentBudget.toFixed(0)}
                  </div>
                  <div className="text-[10px] text-gray-500 font-semibold">Budget</div>
                </div>

                <div>
                  <div className="flex justify-center text-gray-400 mb-1">
                    <TrendingUp className="h-4 w-4" />
                  </div>
                  <div className="text-sm font-extrabold text-gray-900">
                    ₹{totalSpent.toFixed(0)}
                  </div>
                  <div className="text-[10px] text-gray-500 font-semibold">Spent</div>
                </div>

                <div>
                  <div className="flex justify-center text-gray-400 mb-1">
                    <PiggyBank className="h-4 w-4" />
                  </div>
                  <div className="text-sm font-extrabold text-gray-900">
                    ₹{remaining.toFixed(0)}
                  </div>
                  <div className="text-[10px] text-gray-500 font-semibold">Remaining</div>
                </div>
              </div>

              {/* Guidance Banner */}
              <div
                className={`mt-4 rounded-xl p-3 text-xs font-semibold ${
                  isOverBudget
                    ? 'bg-red-50 text-red-700 border border-red-100'
                    : 'bg-blue-50 text-blue-700 border border-blue-100'
                }`}
              >
                {isOverBudget
                  ? `Alert: You are ₹${(totalSpent - currentBudget).toFixed(0)} over your monthly limit.`
                  : currentBudget <= 0
                  ? 'Set a monthly budget below to receive daily spending guidance.'
                  : `Safe Daily Guideline: ₹${averagePerDay.toFixed(0)} per remaining day (${daysRemaining} days left).`}
              </div>
            </div>
          </div>

          {/* Record Completed Ride Action */}
          <div>
            <button
              onClick={() => setIsAddExpenseOpen(!isAddExpenseOpen)}
              className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#111827] hover:bg-black py-3.5 text-sm font-bold text-white transition shadow-sm active:scale-[0.98]"
            >
              <Plus className="h-4 w-4" />
              <span>Record Completed Ride Expense</span>
            </button>
          </div>

          {/* Record Expense Modal Card */}
          {isAddExpenseOpen && (
            <div className="rounded-2xl border border-blue-200 bg-white p-4 shadow-sm animate-in fade-in">
              <div className="flex items-center justify-between mb-3">
                <h5 className="text-xs font-bold uppercase tracking-wider text-gray-800">
                  New Ride Entry
                </h5>
                <button
                  onClick={() => setIsAddExpenseOpen(false)}
                  className="text-gray-400 hover:text-gray-700"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <form onSubmit={handleAddExpense} className="space-y-3">
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="block text-[11px] font-bold text-gray-600 mb-1">
                      Provider
                    </label>
                    <select
                      value={addProvider}
                      onChange={(e) => setAddProvider(e.target.value)}
                      className="w-full rounded-xl border border-gray-200 bg-gray-50 p-2.5 text-xs font-bold text-gray-900"
                    >
                      <option value="Uber">Uber</option>
                      <option value="Ola">Ola</option>
                      <option value="Rapido">Rapido</option>
                      <option value="Auto">Local Auto</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-[11px] font-bold text-gray-600 mb-1">
                      Category
                    </label>
                    <select
                      value={addCategory}
                      onChange={(e) => setAddCategory(e.target.value)}
                      className="w-full rounded-xl border border-gray-200 bg-gray-50 p-2.5 text-xs font-bold text-gray-900"
                    >
                      <option value="Cab">Cab</option>
                      <option value="Auto">Auto</option>
                      <option value="Bike">Bike</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-[11px] font-bold text-gray-600 mb-1">
                    Amount Paid (₹)
                  </label>
                  <input
                    type="number"
                    step="1"
                    placeholder="e.g. 180"
                    value={addAmount}
                    onChange={(e) => setAddAmount(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 bg-gray-50 p-2.5 text-xs font-bold text-gray-900 focus:outline-none focus:border-blue-500"
                  />
                </div>

                {expenseError && (
                  <div className="flex items-center gap-1.5 text-xs text-red-600 font-bold">
                    <AlertCircle className="h-4 w-4" />
                    <span>{expenseError}</span>
                  </div>
                )}

                <button
                  type="submit"
                  className="w-full rounded-xl bg-blue-600 py-2.5 text-xs font-bold text-white hover:bg-blue-700 transition"
                >
                  Save Entry
                </button>
              </form>
            </div>
          )}

          {/* Ride Spending History */}
          <div>
            <h4 className="text-sm font-extrabold text-gray-950 mb-3">
              Recorded Rides ({expenses.length})
            </h4>
            {expenses.length === 0 ? (
              <div className="rounded-2xl border border-gray-200 bg-white p-6 text-center text-xs text-gray-500">
                No rides recorded this month. Add completed trips above to track spending.
              </div>
            ) : (
              <div className="rounded-2xl border border-gray-200 bg-white overflow-hidden divide-y divide-gray-150">
                {expenses.map((expense) => (
                  <div
                    key={expense.id}
                    className="flex items-center justify-between p-3.5 hover:bg-gray-50 transition"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-50 text-blue-600 text-sm">
                        {expense.category.toLowerCase().includes('auto') ? '🛺' : '🚗'}
                      </div>
                      <div>
                        <div className="text-xs font-bold text-gray-950">
                          {expense.provider} {expense.category}
                        </div>
                        <div className="text-[10px] text-gray-400">
                          {new Date(expense.createdAt).toLocaleDateString()}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-xs font-black text-gray-950">
                        ₹{expense.amount.toFixed(0)}
                      </span>
                      <button
                        onClick={() => handleDeleteExpense(expense.id)}
                        className="text-gray-400 hover:text-red-600 transition p-1"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Travel Preferences */}
          <div>
            <h4 className="text-sm font-extrabold text-gray-950 mb-3">
              KaroScore Preference Mode
            </h4>
            <div className="rounded-2xl border border-gray-200 bg-white p-4 space-y-3">
              <span className="text-xs font-bold text-gray-700 block">
                How should KaroScore weight ride attributes?
              </span>

              {/* Mode Options: Budget, Hurry, Balanced */}
              <div
                onClick={() => setMode('balanced')}
                className={`flex items-center justify-between p-3 rounded-xl border transition cursor-pointer ${
                  mode === 'balanced'
                    ? 'border-blue-500 bg-blue-50/60 shadow-2xs'
                    : 'border-gray-200 hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Scale
                    className={`h-4 w-4 ${
                      mode === 'balanced' ? 'text-blue-600' : 'text-gray-400'
                    }`}
                  />
                  <div>
                    <div className="text-xs font-bold text-gray-900">Balanced Choice</div>
                    <div className="text-[10px] text-gray-500">
                      Even distribution of price, speed, and safety
                    </div>
                  </div>
                </div>
                <div
                  className={`h-4 w-4 rounded-full border flex items-center justify-center ${
                    mode === 'balanced' ? 'border-blue-600 bg-blue-600' : 'border-gray-300'
                  }`}
                >
                  {mode === 'balanced' && <div className="h-1.5 w-1.5 rounded-full bg-white" />}
                </div>
              </div>

              <div
                onClick={() => setMode('budget')}
                className={`flex items-center justify-between p-3 rounded-xl border transition cursor-pointer ${
                  mode === 'budget'
                    ? 'border-blue-500 bg-blue-50/60 shadow-2xs'
                    : 'border-gray-200 hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center gap-3">
                  <PiggyBank
                    className={`h-4 w-4 ${
                      mode === 'budget' ? 'text-blue-600' : 'text-gray-400'
                    }`}
                  />
                  <div>
                    <div className="text-xs font-bold text-gray-900">Budget Priority</div>
                    <div className="text-[10px] text-gray-500">
                      Price economy weighted at 40%
                    </div>
                  </div>
                </div>
                <div
                  className={`h-4 w-4 rounded-full border flex items-center justify-center ${
                    mode === 'budget' ? 'border-blue-600 bg-blue-600' : 'border-gray-300'
                  }`}
                >
                  {mode === 'budget' && <div className="h-1.5 w-1.5 rounded-full bg-white" />}
                </div>
              </div>

              <div
                onClick={() => setMode('hurry')}
                className={`flex items-center justify-between p-3 rounded-xl border transition cursor-pointer ${
                  mode === 'hurry'
                    ? 'border-blue-500 bg-blue-50/60 shadow-2xs'
                    : 'border-gray-200 hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Zap
                    className={`h-4 w-4 ${
                      mode === 'hurry' ? 'text-blue-600' : 'text-gray-400'
                    }`}
                  />
                  <div>
                    <div className="text-xs font-bold text-gray-900">Hurry / Speed Priority</div>
                    <div className="text-[10px] text-gray-500">
                      Shortest pickup ETA (30%) & trip duration (25%)
                    </div>
                  </div>
                </div>
                <div
                  className={`h-4 w-4 rounded-full border flex items-center justify-center ${
                    mode === 'hurry' ? 'border-blue-600 bg-blue-600' : 'border-gray-300'
                  }`}
                >
                  {mode === 'hurry' && <div className="h-1.5 w-1.5 rounded-full bg-white" />}
                </div>
              </div>

              {/* Comfort Toggle */}
              <div className="border-t border-gray-150 pt-3 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <Armchair className="h-4 w-4 text-blue-600" />
                  <div>
                    <div className="text-xs font-bold text-gray-950">Comfort Priority</div>
                    <div className="text-[10px] text-gray-500">
                      Give higher importance to AC cabs over open autos
                    </div>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setComfortMode(!comfortMode)}
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    comfortMode ? 'bg-blue-600' : 'bg-gray-200'
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${
                      comfortMode ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Monthly Budget Setting */}
          <div>
            <h4 className="text-sm font-extrabold text-gray-950 mb-3">
              Monthly Budget Amount
            </h4>
            <div className="rounded-2xl border border-gray-200 bg-white p-4">
              <label className="block text-xs text-gray-500 mb-2">
                Set monthly transport cap (₹)
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center text-sm font-bold text-blue-600">
                  ₹
                </span>
                <input
                  type="number"
                  value={budgetInput}
                  onChange={(e) => setBudgetInput(e.target.value)}
                  placeholder="Example: 5000"
                  className="w-full rounded-xl border border-gray-200 bg-gray-50 py-3 pl-8 pr-4 text-sm font-bold text-gray-900 focus:outline-none focus:border-blue-600"
                />
              </div>
            </div>
          </div>

          {/* Save Preferences Button */}
          <div>
            <button
              onClick={handleSavePreferences}
              className="flex w-full items-center justify-center gap-2 rounded-2xl bg-blue-600 hover:bg-blue-700 py-4 text-sm font-bold text-white transition shadow-md shadow-blue-500/20 active:scale-[0.98]"
            >
              {saveSuccess ? (
                <>
                  <CheckCircle2 className="h-5 w-5 text-emerald-300" />
                  <span>Preferences Saved!</span>
                </>
              ) : (
                <>
                  <Save className="h-5 w-5" />
                  <span>Save Preferences & Budget</span>
                </>
              )}
            </button>
          </div>

          {/* Logout Button */}
          <div>
            <button
              onClick={onLogout}
              className="flex w-full items-center justify-center gap-2 rounded-2xl border border-red-200 bg-white hover:bg-red-50 py-3.5 text-sm font-bold text-red-600 transition"
            >
              <LogOut className="h-4 w-4" />
              <span>Sign Out of KaroCab</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
