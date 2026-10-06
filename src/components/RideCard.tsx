import React, { useState } from 'react';
import { Ride, LocationCoordinate } from '../types';
import {
  Car,
  Clock,
  Sparkles,
  ShieldCheck,
  ChevronDown,
  ChevronUp,
  ExternalLink,
  Flame,
  Award,
  Zap,
  Armchair,
  ThumbsUp
} from 'lucide-react';
import { launchProvider } from '../services/providerLauncher';

interface RideCardProps {
  ride: Ride;
  isSelected?: boolean;
  onSelect?: () => void;
  pickupCoord?: LocationCoordinate | null;
  dropCoord?: LocationCoordinate | null;
  pickupAddress?: string;
  dropAddress?: string;
  index?: number;
  className?: string;
  style?: React.CSSProperties;
}

export const RideCard: React.FC<RideCardProps> = ({
  ride,
  isSelected,
  onSelect,
  pickupCoord,
  dropCoord,
  pickupAddress,
  dropAddress,
  index = 0,
  className = '',
  style
}) => {
  const [showScoreDetails, setShowScoreDetails] = useState(false);
  const isAuto = ride.category.toLowerCase().includes('auto');
  const isBestOverall = ride.highlights?.includes('bestOverall');
  const isCheapest = ride.highlights?.includes('cheapest');
  const isFastest = ride.highlights?.includes('fastest');
  const isSafest = ride.highlights?.includes('safest');

  const handleBookClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    launchProvider({
      provider: ride.provider,
      category: ride.category,
      pickupCoord,
      dropCoord,
      pickupAddress,
      dropAddress
    });
  };

  return (
    <div
      onClick={onSelect}
      style={{
        animationDelay: `${Math.min(index * 35, 250)}ms`,
        ...style
      }}
      className={`group relative mb-3 rounded-2xl border p-4 transition-all duration-200 cursor-pointer animate-ride-enter will-change-transform ${
        isBestOverall
          ? 'border-blue-500 bg-gradient-to-br from-blue-50/70 via-white to-indigo-50/30 shadow-md ring-2 ring-blue-500/20'
          : isSelected
          ? 'border-blue-400 bg-blue-50/40 shadow-sm'
          : 'border-gray-200 bg-white hover:border-blue-300 hover:shadow-md'
      } ${className}`}
    >
      {/* Top Highlights Badges */}
      <div className="flex flex-wrap items-center gap-1.5 mb-2.5">
        {isBestOverall && (
          <span className="inline-flex items-center gap-1 rounded-full bg-blue-600 px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-white shadow-xs">
            <Award className="h-3 w-3" />
            Best Overall
          </span>
        )}
        {isCheapest && (
          <span className="inline-flex items-center gap-1 rounded-full bg-emerald-600 px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-white shadow-xs">
            <Flame className="h-3 w-3" />
            Cheapest
          </span>
        )}
        {isFastest && (
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-500 px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-white shadow-xs">
            <Zap className="h-3 w-3" />
            Fastest
          </span>
        )}
        {isSafest && (
          <span className="inline-flex items-center gap-1 rounded-full bg-indigo-600 px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-white shadow-xs">
            <ShieldCheck className="h-3 w-3" />
            Top Safety
          </span>
        )}
      </div>

      {/* Main Row */}
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <div
            className={`flex h-12 w-12 items-center justify-center rounded-2xl transition-transform group-hover:scale-105 ${
              ride.provider.toLowerCase() === 'uber'
                ? 'bg-black text-white'
                : 'bg-amber-400 text-gray-950 font-black'
            }`}
          >
            {isAuto ? (
              <span className="text-2xl leading-none">🛺</span>
            ) : (
              <Car className="h-6 w-6" />
            )}
          </div>

          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-base font-extrabold text-gray-950">
                {ride.provider} {ride.category}
              </span>
              {ride.vehicleCategory && (
                <span className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-1.5 py-0.5 text-[10px] font-bold text-slate-700 border border-slate-200/80">
                  {ride.vehicleCategory}
                  {ride.capacity ? ` • ${ride.capacity} seats` : ''}
                </span>
              )}
            </div>

            <div className="mt-1 flex items-center gap-3 text-xs text-gray-500 font-medium">
              <span className="flex items-center gap-1">
                <Clock className="h-3.5 w-3.5 text-gray-400" />
                ETA: <b>{ride.eta} min</b>
              </span>
              <span>•</span>
              <span>Trip: {ride.duration} min</span>
            </div>
          </div>
        </div>

        {/* Fare & KaroScore */}
        <div className="text-right">
          <div className="text-xl font-black text-gray-950 tracking-tight">
            ₹{Number(ride.fare).toFixed(2)}
          </div>
          <div className="mt-1 flex items-center justify-end gap-1">
            <span className="inline-flex items-center gap-1 rounded-lg bg-blue-100/80 px-2 py-0.5 text-xs font-black text-blue-700">
              <Sparkles className="h-3 w-3" />
              {ride.karoScore}/100
            </span>
          </div>
        </div>
      </div>

      {/* Trust & Quality Indicators */}
      <div className="mt-3.5 flex items-center justify-between border-t border-gray-150/70 pt-2.5 text-[11px] text-gray-600 font-semibold">
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1 text-emerald-700">
            <ShieldCheck className="h-3.5 w-3.5" />
            Safety {ride.safety}/100
          </span>
          <span className="flex items-center gap-1 text-gray-600">
            <Armchair className="h-3.5 w-3.5 text-blue-600" />
            Comfort {ride.comfort}/100
          </span>
          <span className="hidden sm:flex items-center gap-1 text-gray-600">
            <ThumbsUp className="h-3.5 w-3.5 text-indigo-600" />
            Reliability {ride.reliability}/100
          </span>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setShowScoreDetails(!showScoreDetails);
            }}
            className="flex items-center gap-0.5 text-blue-600 hover:text-blue-800 text-[11px] font-bold"
          >
            <span>Score Details</span>
            {showScoreDetails ? (
              <ChevronUp className="h-3.5 w-3.5" />
            ) : (
              <ChevronDown className="h-3.5 w-3.5" />
            )}
          </button>
        </div>
      </div>

      {/* Expandable Transparent KaroScore Breakdown */}
      {showScoreDetails && ride.scores && (
        <div
          onClick={(e) => e.stopPropagation()}
          className="mt-3 rounded-xl bg-gray-50/90 p-3 text-xs border border-gray-200/80 space-y-2 animate-in fade-in duration-200"
        >
          <div className="flex items-center justify-between font-bold text-gray-900 border-b border-gray-200 pb-1.5">
            <span>KaroScore Methodology Breakdown</span>
            <span className="text-blue-600 font-black">{ride.karoScore}/100</span>
          </div>

          <div className="grid grid-cols-2 gap-x-4 gap-y-1.5 text-[11px]">
            <div>
              <div className="flex justify-between text-gray-600">
                <span>Fare Economy ({ride.scoreWeights?.price}%)</span>
                <span className="font-bold">{ride.scores.price}/100</span>
              </div>
              <div className="h-1.5 w-full bg-gray-200 rounded-full mt-0.5 overflow-hidden">
                <div
                  className="h-full bg-emerald-500 rounded-full"
                  style={{ width: `${ride.scores.price}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between text-gray-600">
                <span>Pickup Speed ({ride.scoreWeights?.eta}%)</span>
                <span className="font-bold">{ride.scores.eta}/100</span>
              </div>
              <div className="h-1.5 w-full bg-gray-200 rounded-full mt-0.5 overflow-hidden">
                <div
                  className="h-full bg-blue-500 rounded-full"
                  style={{ width: `${ride.scores.eta}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between text-gray-600">
                <span>Safety Rating ({ride.scoreWeights?.safety}%)</span>
                <span className="font-bold">{ride.scores.safety}/100</span>
              </div>
              <div className="h-1.5 w-full bg-gray-200 rounded-full mt-0.5 overflow-hidden">
                <div
                  className="h-full bg-indigo-500 rounded-full"
                  style={{ width: `${ride.scores.safety}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between text-gray-600">
                <span>Comfort & Hygiene ({ride.scoreWeights?.comfort}%)</span>
                <span className="font-bold">{ride.scores.comfort}/100</span>
              </div>
              <div className="h-1.5 w-full bg-gray-200 rounded-full mt-0.5 overflow-hidden">
                <div
                  className="h-full bg-purple-500 rounded-full"
                  style={{ width: `${ride.scores.comfort}%` }}
                />
              </div>
            </div>
          </div>

          <div className="pt-2 flex justify-between items-center border-t border-gray-200/60 text-[10px] text-gray-500">
            <span>Normalized using min-max scaling across active options.</span>
            <button
              onClick={handleBookClick}
              className="inline-flex items-center gap-1 rounded-lg bg-gray-900 px-2.5 py-1 text-xs font-bold text-white hover:bg-black transition"
            >
              <span>Book on {ride.provider}</span>
              <ExternalLink className="h-3 w-3" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
