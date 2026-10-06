import React from 'react';
import { Tradeoffs } from '../types';
import { Lightbulb } from 'lucide-react';

interface TradeoffCardProps {
  tradeoffs?: Tradeoffs;
}

export const TradeoffCard: React.FC<TradeoffCardProps> = ({ tradeoffs }) => {
  if (!tradeoffs) return null;

  const extraCost =
    tradeoffs.extraCostVsBudget !== undefined
      ? tradeoffs.extraCostVsBudget
      : tradeoffs.budgetButNotSlowest?.extraCostComparedWithCheapest;

  const timeSaved =
    tradeoffs.timeSavedVsSlowest !== undefined
      ? tradeoffs.timeSavedVsSlowest
      : tradeoffs.budgetButNotSlowest?.timeSavedComparedWithSlowest;

  if (extraCost === undefined && timeSaved === undefined) {
    return null;
  }

  return (
    <div className="mb-3 rounded-2xl border border-blue-200 bg-blue-50/70 p-3.5">
      <div className="flex items-center gap-2 text-blue-800">
        <Lightbulb className="h-4 w-4 text-blue-600" />
        <span className="text-sm font-extrabold">Trade-offs Analysis</span>
      </div>

      <div className="mt-2 space-y-1 text-xs text-blue-950 font-medium">
        {extraCost !== undefined && (
          <p>
            • Extra cost vs cheapest option: <span className="font-bold">₹{extraCost}</span>
          </p>
        )}
        {timeSaved !== undefined && (
          <p>
            • Time saved vs slowest ride: <span className="font-bold">{timeSaved} min</span>
          </p>
        )}
      </div>
    </div>
  );
};
