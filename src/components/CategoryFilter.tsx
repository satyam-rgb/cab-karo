import React from 'react';
import { VehicleCategoryFilter, Ride } from '../types';
import { Layers, Car, Users, X, Sparkles } from 'lucide-react';

interface CategoryFilterProps {
  selectedCategory: VehicleCategoryFilter;
  onSelectCategory: (category: VehicleCategoryFilter) => void;
  rides: Ride[];
  compact?: boolean;
}

interface CategoryOption {
  id: VehicleCategoryFilter;
  label: string;
  icon: 'auto' | 'car' | 'users' | 'all';
  description: string;
}

const CATEGORIES: CategoryOption[] = [
  { id: 'all', label: 'All Rides', icon: 'all', description: 'All vehicle types' },
  { id: 'Auto', label: 'Auto', icon: 'auto', description: '3 seats • Affordable' },
  { id: 'Mini', label: 'Mini', icon: 'car', description: '4 seats • Compact' },
  { id: 'Sedan', label: 'Sedan', icon: 'car', description: '4 seats • Prime comfort' },
  { id: 'XL', label: 'XL (SUV)', icon: 'users', description: '6 seats • Spacious' }
];

export const CategoryFilter: React.FC<CategoryFilterProps> = ({
  selectedCategory,
  onSelectCategory,
  rides,
  compact = false
}) => {
  // Compute counts and min fares per category
  const getCategoryStats = (catId: VehicleCategoryFilter) => {
    const matching = catId === 'all'
      ? rides
      : rides.filter((r) => r.vehicleCategory === catId);
    
    const count = matching.length;
    const minFare = count > 0 ? Math.min(...matching.map((r) => Number(r.fare))) : null;
    return { count, minFare };
  };

  const renderIcon = (icon: CategoryOption['icon']) => {
    switch (icon) {
      case 'auto':
        return <span className="text-base leading-none select-none">🛺</span>;
      case 'car':
        return <Car className="h-4 w-4" />;
      case 'users':
        return <Users className="h-4 w-4" />;
      case 'all':
      default:
        return <Layers className="h-4 w-4" />;
    }
  };

  return (
    <div className="space-y-2">
      {/* Category Tabs Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5 text-xs font-extrabold text-gray-900 tracking-tight">
          <Sparkles className="h-3.5 w-3.5 text-blue-600" />
          <span>Vehicle Category Filter</span>
        </div>
        {selectedCategory !== 'all' && (
          <button
            type="button"
            onClick={() => onSelectCategory('all')}
            className="inline-flex items-center gap-1 text-[11px] font-bold text-blue-600 hover:text-blue-800 transition py-0.5 px-2 rounded-lg hover:bg-blue-50"
          >
            <span>Show all</span>
            <X className="h-3 w-3" />
          </button>
        )}
      </div>

      {/* Pill buttons list */}
      <div
        role="tablist"
        aria-label="Vehicle category filters"
        className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1 pt-0.5"
      >
        {CATEGORIES.map((cat) => {
          const isSelected = selectedCategory === cat.id;
          const { count, minFare } = getCategoryStats(cat.id);

          return (
            <button
              key={cat.id}
              role="tab"
              aria-selected={isSelected}
              type="button"
              onClick={() => onSelectCategory(isSelected && cat.id !== 'all' ? 'all' : cat.id)}
              className={`group relative flex items-center gap-2 rounded-xl transition-all duration-200 shrink-0 cursor-pointer select-none text-left ${
                compact ? 'px-3 py-2 text-xs' : 'px-3.5 py-2.5 text-xs'
              } ${
                isSelected
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-500/25 ring-2 ring-blue-600/30'
                  : 'bg-slate-100 hover:bg-slate-200/80 text-slate-700 border border-slate-200/70 hover:border-slate-300'
              }`}
            >
              <div
                className={`flex items-center justify-center rounded-lg transition-colors ${
                  isSelected
                    ? 'text-white'
                    : 'text-slate-600 group-hover:text-slate-900'
                }`}
              >
                {renderIcon(cat.icon)}
              </div>

              <div className="flex flex-col">
                <div className="flex items-center gap-1.5">
                  <span className="font-extrabold tracking-tight">
                    {cat.label}
                  </span>
                  <span
                    className={`inline-flex items-center justify-center rounded-full px-1.5 py-0.2 text-[10px] font-black ${
                      isSelected
                        ? 'bg-white/20 text-white'
                        : 'bg-white text-slate-700 border border-slate-200 shadow-2xs'
                    }`}
                  >
                    {count}
                  </span>
                </div>

                {minFare !== null && !compact && (
                  <span
                    className={`text-[10px] font-semibold leading-tight ${
                      isSelected ? 'text-blue-100' : 'text-slate-500'
                    }`}
                  >
                    from ₹{Math.round(minFare)}
                  </span>
                )}
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};
