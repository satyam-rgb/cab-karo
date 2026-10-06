import React from 'react';
import { FarePrediction } from '../types';
import { TrendingUp, TrendingDown, Minus, Activity } from 'lucide-react';

interface FarePredictionCardProps {
  prediction?: FarePrediction;
}

export const FarePredictionCard: React.FC<FarePredictionCardProps> = ({
  prediction
}) => {
  if (!prediction) return null;

  const isUp = prediction.trend === 'up';
  const isDown = prediction.trend === 'down';

  return (
    <div className="mb-4 rounded-2xl border border-indigo-100 bg-gradient-to-br from-indigo-50/60 to-purple-50/40 p-4 shadow-sm">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-white shadow-sm">
            <Activity className="h-4 w-4" />
          </div>
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-indigo-900">
              ML Fare Prediction
            </h4>
            <p className="text-[11px] text-gray-500 font-medium">
              Linear Regression baseline
            </p>
          </div>
        </div>

        <div
          className={`flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-extrabold ${
            isUp
              ? 'bg-red-100 text-red-700'
              : isDown
              ? 'bg-emerald-100 text-emerald-700'
              : 'bg-blue-100 text-blue-700'
          }`}
        >
          {isUp ? (
            <>
              <TrendingUp className="h-3.5 w-3.5" /> Fares Rising
            </>
          ) : isDown ? (
            <>
              <TrendingDown className="h-3.5 w-3.5" /> Fares Dropping
            </>
          ) : (
            <>
              <Minus className="h-3.5 w-3.5" /> Stable Trend
            </>
          )}
        </div>
      </div>

      <div className="mt-3.5 grid grid-cols-2 gap-2.5">
        <div className="rounded-xl border border-indigo-100 bg-white/80 p-2.5">
          <span className="text-[11px] text-gray-500 font-medium">Expected Fare</span>
          <p className="mt-0.5 text-base font-extrabold text-indigo-950">
            ₹{prediction.predictedFare.toFixed(2)}
          </p>
          <span className="text-[10px] text-gray-400">
            Current: ₹{prediction.currentFare.toFixed(2)}
          </span>
        </div>

        <div className="rounded-xl border border-indigo-100 bg-white/80 p-2.5">
          <span className="text-[11px] text-gray-500 font-medium">Recommendation</span>
          <p className="mt-0.5 text-sm font-extrabold text-indigo-600">
            {prediction.recommendation}
          </p>
          <span className="text-[10px] text-gray-400">
            Change: {prediction.expectedChangePercent > 0 ? '+' : ''}
            {prediction.expectedChangePercent.toFixed(1)}%
          </span>
        </div>
      </div>

      {prediction.metrics && (
        <div className="mt-2.5 flex items-center justify-between border-t border-indigo-100/60 pt-2 text-[10px] text-gray-500 font-medium">
          <span>Model: MAE: ₹{prediction.metrics.mae}</span>
          <span>RMSE: ₹{prediction.metrics.rmse}</span>
          <span>R²: {prediction.metrics.r2}</span>
        </div>
      )}
    </div>
  );
};
