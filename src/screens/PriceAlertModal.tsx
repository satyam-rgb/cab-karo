import React, { useState } from 'react';
import { X, Bell, CheckCircle2, Trash2, ArrowDownRight, Sparkles, AlertCircle } from 'lucide-react';
import { Ride, PriceAlert } from '../types';
import { storageService } from '../services/storageService';

interface PriceAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
  rides: Ride[];
  fromAddress: string;
  toAddress: string;
  distance?: number;
  duration?: number;
  initialSelectedRide?: Ride | null;
}

export const PriceAlertModal: React.FC<PriceAlertModalProps> = ({
  isOpen,
  onClose,
  rides,
  fromAddress,
  toAddress,
  distance,
  duration,
  initialSelectedRide
}) => {
  const [selectedRideId, setSelectedRideId] = useState<string>(
    initialSelectedRide?.id || (rides.length > 0 ? rides[0].id : '')
  );
  const selectedRide = rides.find((r) => r.id === selectedRideId) || rides[0];

  const [targetPrice, setTargetPrice] = useState<string>(
    selectedRide ? (selectedRide.fare * 0.9).toFixed(0) : ''
  );
  const [alerts, setAlerts] = useState<PriceAlert[]>(() =>
    storageService.getPriceAlerts()
  );
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [validationError, setValidationError] = useState('');

  if (!isOpen) return null;

  const currentFare = selectedRide ? selectedRide.fare : 0;
  const parsedTarget = parseFloat(targetPrice) || 0;
  const savings = Math.max(0, currentFare - parsedTarget);
  const savingsPercent = currentFare > 0 ? (savings / currentFare) * 100 : 0;

  const handleSelectRide = (ride: Ride) => {
    setSelectedRideId(ride.id);
    setTargetPrice((ride.fare * 0.9).toFixed(0));
    setValidationError('');
  };

  const handleApplyDiscount = (pct: number) => {
    if (!selectedRide) return;
    const discounted = Math.round(selectedRide.fare * (1 - pct / 100));
    setTargetPrice(discounted.toString());
    setValidationError('');
  };

  const handleSaveAlert = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedRide) return;
    const target = parseFloat(targetPrice);

    if (isNaN(target) || target <= 0) {
      setValidationError('Please enter a valid target fare.');
      return;
    }

    if (target >= currentFare) {
      setValidationError('Target fare should be lower than the current estimated fare to set an alert.');
      return;
    }

    const newAlert = storageService.savePriceAlert({
      provider: selectedRide.provider,
      category: selectedRide.category,
      currentFare: selectedRide.fare,
      targetPrice: target,
      from: fromAddress || 'Nagpur Railway Station',
      to: toAddress || 'Nagpur Airport',
      distance,
      duration,
      status: 'active'
    });

    setAlerts([newAlert, ...alerts]);
    setSaveSuccess(true);
    setValidationError('');
    setTimeout(() => {
      setSaveSuccess(false);
      onClose();
    }, 1200);
  };

  const handleDeleteAlert = (id: string) => {
    const updated = storageService.deletePriceAlert(id);
    setAlerts(updated);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-md flex-col rounded-[28px] bg-white shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-150 p-5 bg-white shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 shadow-xs">
              <Bell className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-black text-gray-950">Fare Price Alert</h3>
              <p className="text-xs text-gray-500 font-medium">
                Track fare drops on your route
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
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* Route Overview */}
          <div className="rounded-2xl bg-slate-50 p-3.5 border border-slate-200/80 text-xs">
            <div className="font-extrabold text-slate-900 text-sm mb-1">
              {fromAddress || 'Pickup'} → {toAddress || 'Destination'}
            </div>
            {distance && duration && (
              <span className="text-slate-500 font-semibold">
                {distance} km • {duration} min
              </span>
            )}
          </div>

          {/* Ride Selector */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-gray-600 mb-2">
              Select Ride to Track
            </h4>
            <div className="space-y-2">
              {rides.map((ride) => {
                const isSelected = ride.id === selectedRideId;
                return (
                  <div
                    key={ride.id}
                    onClick={() => handleSelectRide(ride)}
                    className={`flex items-center justify-between p-3 rounded-2xl border transition cursor-pointer ${
                      isSelected
                        ? 'border-blue-500 bg-blue-50/60 shadow-xs ring-1 ring-blue-500'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                    }`}
                  >
                    <div>
                      <div className="text-sm font-bold text-gray-950">
                        {ride.provider} {ride.category}
                      </div>
                      <div className="text-xs text-gray-500">
                        Current fare: <b>₹{ride.fare.toFixed(2)}</b>
                      </div>
                    </div>
                    <div
                      className={`h-5 w-5 rounded-full border-2 flex items-center justify-center ${
                        isSelected
                          ? 'border-blue-600 bg-blue-600 text-white'
                          : 'border-gray-300'
                      }`}
                    >
                      {isSelected && <div className="h-2 w-2 rounded-full bg-white" />}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Target Price Form */}
          {selectedRide && (
            <form onSubmit={handleSaveAlert} className="space-y-3.5">
              {/* Fare Delta Comparison Card */}
              <div className="rounded-2xl bg-gradient-to-br from-indigo-50/70 to-blue-50/60 p-4 border border-indigo-100">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-[11px] text-gray-500 font-bold uppercase">
                      Current Estimate
                    </span>
                    <div className="text-lg font-black text-gray-900">
                      ₹{currentFare.toFixed(2)}
                    </div>
                  </div>

                  <ArrowDownRight className="h-5 w-5 text-emerald-600" />

                  <div className="text-right">
                    <span className="text-[11px] text-emerald-700 font-bold uppercase">
                      Target Goal
                    </span>
                    <div className="text-lg font-black text-emerald-700">
                      ₹{parsedTarget > 0 ? parsedTarget.toFixed(2) : '--'}
                    </div>
                  </div>
                </div>

                {savings > 0 && (
                  <div className="mt-2 flex items-center gap-1.5 text-xs font-extrabold text-emerald-700 border-t border-indigo-100 pt-2">
                    <Sparkles className="h-3.5 w-3.5" />
                    <span>
                      Target Savings: ₹{savings.toFixed(0)} ({savingsPercent.toFixed(0)}% off)
                    </span>
                  </div>
                )}
              </div>

              {/* Quick Preset Buttons */}
              <div>
                <span className="block text-[11px] font-bold text-gray-500 mb-1.5">
                  Quick Discount Presets
                </span>
                <div className="grid grid-cols-4 gap-2">
                  {[5, 10, 15, 20].map((pct) => (
                    <button
                      key={pct}
                      type="button"
                      onClick={() => handleApplyDiscount(pct)}
                      className="rounded-xl border border-gray-200 bg-white py-2 text-xs font-extrabold text-gray-800 hover:border-blue-500 hover:text-blue-600 transition shadow-2xs"
                    >
                      -{pct}%
                    </button>
                  ))}
                </div>
              </div>

              {/* Custom Input */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Target Fare Amount (₹)
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center text-sm font-bold text-gray-400">
                    ₹
                  </span>
                  <input
                    type="number"
                    step="1"
                    value={targetPrice}
                    onChange={(e) => {
                      setTargetPrice(e.target.value);
                      setValidationError('');
                    }}
                    placeholder="Enter target fare"
                    className="w-full rounded-2xl border border-gray-200 bg-white py-3 pl-8 pr-4 text-sm font-extrabold text-gray-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                  />
                </div>
              </div>

              {validationError && (
                <div className="flex items-center gap-1.5 rounded-xl bg-red-50 p-2.5 text-xs font-bold text-red-600 border border-red-100">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  <span>{validationError}</span>
                </div>
              )}

              <button
                type="submit"
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-blue-600 py-3.5 text-sm font-bold text-white hover:bg-blue-700 transition shadow-md shadow-blue-500/20 active:scale-[0.98]"
              >
                {saveSuccess ? (
                  <>
                    <CheckCircle2 className="h-4 w-4 text-emerald-300" />
                    <span>Price Alert Active!</span>
                  </>
                ) : (
                  <>
                    <Bell className="h-4 w-4" />
                    <span>Set Route Price Alert</span>
                  </>
                )}
              </button>
            </form>
          )}

          {/* Active Alerts List */}
          <div className="border-t border-gray-150 pt-4">
            <h4 className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-2.5">
              Active Price Alerts ({alerts.length})
            </h4>
            {alerts.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-gray-200 p-4 text-center text-xs text-gray-400 font-medium">
                No active price alerts set. Select a ride above to begin monitoring.
              </div>
            ) : (
              <div className="space-y-2">
                {alerts.map((alert) => (
                  <div
                    key={alert.id}
                    className="flex items-center justify-between rounded-xl border border-gray-200 bg-gray-50/80 p-3 text-xs"
                  >
                    <div>
                      <div className="font-extrabold text-gray-950">
                        {alert.provider} {alert.category} • Target ₹{alert.targetPrice.toFixed(2)}
                      </div>
                      <div className="text-gray-500 truncate max-w-[200px]">
                        {alert.from} → {alert.to}
                      </div>
                    </div>
                    <button
                      onClick={() => handleDeleteAlert(alert.id)}
                      className="p-1.5 text-gray-400 hover:text-red-600 rounded-lg transition"
                      title="Remove Alert"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
