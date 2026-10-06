import React, { useState } from 'react';
import { PricingResponse, Ride, ScoreMode, LocationCoordinate, VehicleCategoryFilter } from '../types';
import { RideCard } from './RideCard';
import { RecommendationCard } from './RecommendationCard';
import { TradeoffCard } from './TradeoffCard';
import { FarePredictionCard } from './FarePredictionCard';
import { CategoryFilter } from './CategoryFilter';
import {
  X,
  Navigation,
  Bell,
  ExternalLink,
  Car,
  PiggyBank,
  Zap,
  Scale,
  Sparkles,
  Info,
  RotateCw
} from 'lucide-react';
import { launchProvider } from '../services/providerLauncher';
import { calculateKaroScore } from '../services/pricingService';

interface ComparisonModalProps {
  isOpen: boolean;
  onClose: () => void;
  pricingData: PricingResponse | null;
  fromAddress: string;
  toAddress: string;
  originCoord?: LocationCoordinate | null;
  destinationCoord?: LocationCoordinate | null;
  onSetPriceAlert: (ride: Ride) => void;
  initialCategory?: VehicleCategoryFilter;
  onRefreshFares?: () => Promise<void> | void;
  isRefreshing?: boolean;
}

export const ComparisonModal: React.FC<ComparisonModalProps> = ({
  isOpen,
  onClose,
  pricingData,
  fromAddress,
  toAddress,
  originCoord,
  destinationCoord,
  onSetPriceAlert,
  initialCategory = 'all',
  onRefreshFares,
  isRefreshing = false
}) => {
  const [activeMode, setActiveMode] = useState<ScoreMode>('balanced');
  const [selectedRideId, setSelectedRideId] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<VehicleCategoryFilter>(initialCategory);
  const [refreshCount, setRefreshCount] = useState(0);
  const [isLocalRefreshing, setIsLocalRefreshing] = useState(false);

  if (!isOpen || !pricingData) return null;

  const handleRefresh = async () => {
    setIsLocalRefreshing(true);
    try {
      if (onRefreshFares) {
        await onRefreshFares();
      }
    } finally {
      setRefreshCount((c) => c + 1);
      setTimeout(() => {
        setIsLocalRefreshing(false);
      }, 450);
    }
  };

  // Dynamically re-evaluate rides and scores when user switches mode
  const rides = calculateKaroScore(pricingData.rides, activeMode);

  // Filter rides based on user's category preference (Mini, Sedan, XL, Auto, or All)
  const filteredRides = rides.filter((ride) => {
    if (selectedCategory === 'all') return true;
    return ride.vehicleCategory === selectedCategory;
  });

  const getRide = (id: string | null | undefined): Ride | null => {
    if (!id) return null;
    return rides.find((r) => r.id === id) || null;
  };

  const bestOverall = getRide(pricingData.recommendations.bestOverall);
  const cheapest = getRide(pricingData.recommendations.cheapest || pricingData.recommendations.bestBudget);
  const fastest = getRide(pricingData.recommendations.fastest);
  const budgetButNotSlowest = getRide(pricingData.recommendations.budgetButNotSlowest);
  const balanced = getRide(pricingData.recommendations.balanced);

  const handleOpenOla = () => {
    launchProvider({
      provider: 'Ola',
      category: selectedCategory !== 'all' ? selectedCategory : 'Cab',
      pickupCoord: originCoord,
      dropCoord: destinationCoord,
      pickupAddress: fromAddress,
      dropAddress: toAddress
    });
  };

  const handleOpenUber = () => {
    launchProvider({
      provider: 'Uber',
      category: selectedCategory !== 'all' ? selectedCategory : 'Cab',
      pickupCoord: originCoord,
      dropCoord: destinationCoord,
      pickupAddress: fromAddress,
      dropAddress: toAddress
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-0 sm:p-4">
      <div className="relative flex max-h-[94vh] sm:max-h-[90vh] w-full max-w-2xl flex-col rounded-t-[28px] sm:rounded-[28px] bg-white shadow-2xl overflow-hidden animate-in slide-in-from-bottom duration-300">
        {/* Modal Header */}
        <div className="flex items-center justify-between border-b border-gray-150 p-4 sm:p-5 bg-white shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 sm:h-12 sm:w-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-600 shadow-xs">
              <Car className="h-6 w-6" />
            </div>
            <div>
              <h3 className="text-lg sm:text-xl font-black text-gray-950 tracking-tight">
                Cab Comparison
              </h3>
              <p className="text-xs text-gray-500 font-medium">
                Transparent fares & KaroScore evaluation
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
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-5">
          {/* Trip Summary Card */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 rounded-2xl bg-slate-50 border border-slate-200/80 p-3.5">
            <div className="flex items-center gap-2.5 text-xs text-slate-700 font-bold">
              <Navigation className="h-4 w-4 text-blue-600 shrink-0" />
              <span className="truncate">
                {fromAddress || 'Pickup'} → {toAddress || 'Destination'}
              </span>
            </div>
            <div className="inline-flex items-center gap-2 rounded-xl bg-white px-3 py-1 text-xs font-black text-slate-900 border border-slate-200/60 shadow-2xs self-start sm:self-auto">
              <span>{pricingData.distance} km</span>
              <span className="text-slate-300">•</span>
              <span>{pricingData.duration} min</span>
            </div>
          </div>

          {/* Mode Switcher Tabs */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-1.5 text-xs font-extrabold text-gray-800">
                <Sparkles className="h-3.5 w-3.5 text-blue-600" />
                <span>KaroScore Optimization Mode</span>
              </div>
              <span className="text-[11px] text-gray-400 font-medium">
                Adjusts factor weighting
              </span>
            </div>

            <div className="grid grid-cols-3 gap-2 rounded-2xl bg-gray-100 p-1">
              <button
                type="button"
                onClick={() => setActiveMode('balanced')}
                className={`flex items-center justify-center gap-1.5 rounded-xl py-2 px-3 text-xs font-bold transition ${
                  activeMode === 'balanced'
                    ? 'bg-white text-blue-600 shadow-xs'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                <Scale className="h-3.5 w-3.5" />
                <span>Balanced</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveMode('budget')}
                className={`flex items-center justify-center gap-1.5 rounded-xl py-2 px-3 text-xs font-bold transition ${
                  activeMode === 'budget'
                    ? 'bg-white text-emerald-700 shadow-xs'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                <PiggyBank className="h-3.5 w-3.5" />
                <span>Budget</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveMode('hurry')}
                className={`flex items-center justify-center gap-1.5 rounded-xl py-2 px-3 text-xs font-bold transition ${
                  activeMode === 'hurry'
                    ? 'bg-white text-amber-700 shadow-xs'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                <Zap className="h-3.5 w-3.5" />
                <span>Hurry</span>
              </button>
            </div>
          </div>

          {/* Vehicle Category Filter (Mini, Sedan, XL, Auto, All) */}
          <CategoryFilter
            selectedCategory={selectedCategory}
            onSelectCategory={setSelectedCategory}
            rides={rides}
          />

          {/* Available Rides List */}
          <div>
            <div className="flex items-center justify-between mb-2.5">
              <div className="flex items-center gap-2">
                <h4 className="text-sm sm:text-base font-extrabold text-gray-950">
                  Available Rides ({filteredRides.length}{selectedCategory !== 'all' ? ` of ${rides.length}` : ''})
                </h4>
                {selectedCategory !== 'all' && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 border border-blue-200/80 px-2 py-0.5 text-[10px] font-extrabold text-blue-700">
                    {selectedCategory}
                  </span>
                )}
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleRefresh}
                  disabled={isRefreshing || isLocalRefreshing}
                  title="Refresh fares and ETAs"
                  className="inline-flex items-center gap-1.5 rounded-xl px-2.5 py-1 text-[11px] font-bold text-gray-700 hover:text-blue-600 hover:bg-blue-50/70 border border-gray-200/80 shadow-2xs transition active:scale-95 disabled:opacity-60 cursor-pointer"
                >
                  <RotateCw
                    className={`h-3 w-3 ${isRefreshing || isLocalRefreshing ? 'animate-refresh-spin text-blue-600' : 'text-gray-500'}`}
                  />
                  <span>{isRefreshing || isLocalRefreshing ? 'Updating...' : 'Refresh Fares'}</span>
                </button>
                <span className="text-[11px] text-gray-500 font-semibold hidden sm:flex items-center gap-1">
                  <Info className="h-3 w-3" />
                  Tap for breakdown
                </span>
              </div>
            </div>

            {filteredRides.length > 0 ? (
              <div
                key={`filtered-rides-${selectedCategory}-${refreshCount}-${pricingData.farePrediction.currentFare}`}
                className="space-y-1 transition-all duration-300"
              >
                {filteredRides.map((ride, idx) => (
                  <RideCard
                    key={`${ride.id}-${selectedCategory}-${refreshCount}`}
                    ride={ride}
                    index={idx}
                    isSelected={selectedRideId === ride.id}
                    onSelect={() => setSelectedRideId(ride.id)}
                    pickupCoord={originCoord}
                    dropCoord={destinationCoord}
                    pickupAddress={fromAddress}
                    dropAddress={toAddress}
                  />
                ))}
              </div>
            ) : (
              <div className="rounded-2xl border border-dashed border-gray-200 bg-gray-50/70 p-6 text-center">
                <div className="mx-auto flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-gray-400 shadow-2xs mb-2.5">
                  <Car className="h-5 w-5 text-gray-400" />
                </div>
                <p className="text-sm font-black text-gray-900">
                  No {selectedCategory} rides available
                </p>
                <p className="text-xs text-gray-500 mt-1 max-w-xs mx-auto">
                  We couldn't find any {selectedCategory} options for this specific route.
                </p>
                <button
                  type="button"
                  onClick={() => setSelectedCategory('all')}
                  className="mt-3.5 inline-flex items-center gap-1.5 rounded-xl bg-blue-600 px-3.5 py-2 text-xs font-bold text-white hover:bg-blue-700 transition shadow-xs"
                >
                  <span>Show All Rides ({rides.length})</span>
                </button>
              </div>
            )}
          </div>

          {/* ML Fare Prediction Card */}
          <FarePredictionCard prediction={pricingData.farePrediction} />

          {/* Smart Recommendations */}
          <div>
            <h4 className="text-sm sm:text-base font-extrabold text-gray-950 mb-2.5">
              Smart Decision Picks
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <RecommendationCard
                emoji="🏆"
                title="Best Overall"
                ride={bestOverall}
                explanation={pricingData.recommendations.explanations?.bestOverall}
              />
              <RecommendationCard
                emoji="💰"
                title="Cheapest Fare"
                ride={cheapest}
                explanation={pricingData.recommendations.explanations?.cheapest || pricingData.recommendations.explanations?.bestBudget}
              />
              <RecommendationCard
                emoji="⚡"
                title="Fastest Arrival"
                ride={fastest}
                explanation={pricingData.recommendations.explanations?.fastest}
              />
              <RecommendationCard
                emoji="⚖️"
                title="Balanced Choice"
                ride={balanced}
                explanation={pricingData.recommendations.balancedExplanation}
              />
            </div>

            {budgetButNotSlowest && budgetButNotSlowest.id !== cheapest?.id && (
              <div className="mt-2">
                <RecommendationCard
                  emoji="💡"
                  title="Budget but Not Slowest"
                  ride={budgetButNotSlowest}
                  explanation={pricingData.recommendations.budgetButNotSlowestExplanation}
                />
              </div>
            )}

            <div className="mt-2">
              <TradeoffCard tradeoffs={pricingData.tradeoffs} />
            </div>
          </div>

          {/* Price Alert Button */}
          <div>
            <button
              onClick={() => onSetPriceAlert(cheapest || rides[0])}
              className="flex w-full items-center justify-center gap-2 rounded-2xl border border-blue-200 bg-white py-3.5 text-sm font-bold text-blue-600 hover:bg-blue-50/50 transition shadow-2xs"
            >
              <Bell className="h-4 w-4" />
              <span>Set Price Alert for this Route</span>
            </button>
          </div>

          {/* Open Provider Action Buttons */}
          <div className="grid grid-cols-2 gap-3 pt-1">
            <button
              onClick={handleOpenOla}
              className="group flex items-center justify-center gap-2 rounded-2xl bg-amber-400 hover:bg-amber-500 py-3.5 text-sm font-black text-gray-950 transition shadow-xs active:scale-[0.98]"
            >
              <span>Open Ola</span>
              <ExternalLink className="h-4 w-4 transition group-hover:translate-x-0.5" />
            </button>
            <button
              onClick={handleOpenUber}
              className="group flex items-center justify-center gap-2 rounded-2xl bg-black hover:bg-gray-800 py-3.5 text-sm font-black text-white transition shadow-xs active:scale-[0.98]"
            >
              <span>Open Uber</span>
              <ExternalLink className="h-4 w-4 transition group-hover:translate-x-0.5" />
            </button>
          </div>

          {/* Disclaimer */}
          <p className="text-center text-[11px] text-gray-400 font-medium pb-2">
            Fares shown are KaroCab estimated values based on verified city rates. Mobile app opens native booking intents when installed.
          </p>
        </div>
      </div>
    </div>
  );
};
