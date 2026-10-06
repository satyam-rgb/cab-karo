import { UserProfile, Expense, PriceAlert, EmergencyContact } from '../types';

const PROFILE_KEY = 'karocab_user_profile';
const EXPENSES_KEY = 'karocab_expenses';
const ALERTS_KEY = 'karocab_price_alerts';
const EMERGENCY_KEY = 'karocab_emergency_contact';
const ONBOARDING_KEY = 'karocab_onboarded';

export const storageService = {
  getUserProfile(): UserProfile | null {
    try {
      const data = localStorage.getItem(PROFILE_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  },

  saveUserProfile(profile: Partial<UserProfile>): UserProfile {
    const existing = storageService.getUserProfile();
    const updated: UserProfile = {
      phone: profile.phone ?? existing?.phone ?? '+919876543210',
      monthlyBudget: profile.monthlyBudget ?? existing?.monthlyBudget ?? 4500,
      preferences: {
        mode: profile.preferences?.mode ?? existing?.preferences?.mode ?? 'balanced',
        comfort: profile.preferences?.comfort ?? existing?.preferences?.comfort ?? false,
      },
      createdAt: existing?.createdAt ?? new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
    };
    localStorage.setItem(PROFILE_KEY, JSON.stringify(updated));
    return updated;
  },

  logoutUser() {
    localStorage.removeItem(PROFILE_KEY);
  },

  isOnboardingCompleted(): boolean {
    return localStorage.getItem(ONBOARDING_KEY) === 'true';
  },

  setOnboardingCompleted(completed: boolean) {
    localStorage.setItem(ONBOARDING_KEY, completed ? 'true' : 'false');
  },

  getExpenses(): Expense[] {
    try {
      const data = localStorage.getItem(EXPENSES_KEY);
      if (data) return JSON.parse(data);
    } catch {
      // fallback
    }
    // Default initial mock expenses if empty to make current month tracking immediately visible
    const initial: Expense[] = [
      {
        id: 'exp-1',
        provider: 'Uber',
        category: 'Cab',
        amount: 280,
        type: 'ride',
        createdAt: new Date(Date.now() - 2 * 86400000).toISOString()
      },
      {
        id: 'exp-2',
        provider: 'Ola',
        category: 'Auto',
        amount: 110,
        type: 'ride',
        createdAt: new Date(Date.now() - 5 * 86400000).toISOString()
      }
    ];
    localStorage.setItem(EXPENSES_KEY, JSON.stringify(initial));
    return initial;
  },

  addExpense(expense: Omit<Expense, 'id' | 'createdAt'>): Expense {
    const expenses = storageService.getExpenses();
    const newExpense: Expense = {
      ...expense,
      id: 'exp-' + Date.now(),
      createdAt: new Date().toISOString()
    };
    const updated = [newExpense, ...expenses];
    localStorage.setItem(EXPENSES_KEY, JSON.stringify(updated));
    return newExpense;
  },

  deleteExpense(id: string) {
    const expenses = storageService.getExpenses().filter((e) => e.id !== id);
    localStorage.setItem(EXPENSES_KEY, JSON.stringify(expenses));
    return expenses;
  },

  getPriceAlerts(): PriceAlert[] {
    try {
      const data = localStorage.getItem(ALERTS_KEY);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  savePriceAlert(alert: Omit<PriceAlert, 'id' | 'createdAt'>): PriceAlert {
    const alerts = storageService.getPriceAlerts();
    const newAlert: PriceAlert = {
      ...alert,
      id: 'alert-' + Date.now(),
      createdAt: new Date().toISOString()
    };
    const updated = [newAlert, ...alerts];
    localStorage.setItem(ALERTS_KEY, JSON.stringify(updated));
    return newAlert;
  },

  deletePriceAlert(id: string) {
    const alerts = storageService.getPriceAlerts().filter((a) => a.id !== id);
    localStorage.setItem(ALERTS_KEY, JSON.stringify(alerts));
    return alerts;
  },

  getEmergencyContact(): EmergencyContact {
    try {
      const data = localStorage.getItem(EMERGENCY_KEY);
      if (data) return JSON.parse(data);
    } catch {
      // fallback
    }
    return {
      name: 'Family / Guardian',
      phone: '+919876543210'
    };
  },

  saveEmergencyContact(contact: EmergencyContact) {
    localStorage.setItem(EMERGENCY_KEY, JSON.stringify(contact));
  }
};
