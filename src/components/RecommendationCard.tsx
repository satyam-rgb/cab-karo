import React from 'react';
import { Ride } from '../types';

interface RecommendationCardProps {
  emoji: string;
  title: string;
  ride?: Ride | null;
  explanation?: string;
}

export const RecommendationCard: React.FC<RecommendationCardProps> = ({
  emoji,
  title,
  ride,
  explanation
}) => {
  if (!ride) {
    return (
      <div className="mb-2 rounded-2xl border border-gray-200 bg-gray-50 p-3.5 text-sm text-gray-500 font-medium">
        {emoji} {title}: N/A
      </div>
    );
  }

  return (
    <div className="mb-2.5 rounded-2xl border border-gray-200 bg-gray-50/80 p-3.5 transition-all duration-200 hover:border-blue-200 animate-ride-enter">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-2.5">
          <span className="text-xl leading-none mt-0.5">{emoji}</span>
          <div>
            <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
              {title}
            </span>
            <div className="text-[15px] font-extrabold text-gray-900 mt-0.5">
              {ride.provider} {ride.category}
            </div>
            <div className="text-xs font-medium text-gray-500 mt-0.5">
              ₹{Number(ride.fare).toFixed(2)} • ETA {ride.eta} min
            </div>
          </div>
        </div>

        <div className="rounded-lg bg-blue-100/70 px-2.5 py-1 text-xs font-extrabold text-blue-700 whitespace-nowrap">
          {ride.karoScore}/100
        </div>
      </div>

      {explanation && explanation.trim().length > 0 && (
        <div className="mt-2 text-[11px] leading-relaxed text-gray-600 border-t border-gray-200/60 pt-1.5 font-medium">
          {explanation}
        </div>
      )}
    </div>
  );
};
