import React, { useState, useEffect, useRef } from 'react';
import {
  MessageSquare,
  Compass,
  User,
  ShieldAlert,
  MapPin,
  Flag,
  ArrowUpDown,
  Search,
  Sparkles,
  Car,
  Clock,
  Layers,
  ChevronRight,
  TrendingUp,
  LocateFixed,
  X,
  GraduationCap,
  HeartPulse,
  Train,
  Plane,
  Mail,
  Store,
  Navigation
} from 'lucide-react';
import { MapView } from '../components/MapView';
import { ComparisonModal } from '../components/ComparisonModal';
import { DestinationExplorerModal } from './DestinationExplorerModal';
import { KaroSafeModal } from './KaroSafeModal';
import { PriceAlertModal } from './PriceAlertModal';
import { ProfileModal } from './ProfileModal';
import { ChatScreenModal } from './ChatScreenModal';
import { RideCard } from '../components/RideCard';
import { CategoryFilter } from '../components/CategoryFilter';
import {
  LocationCoordinate,
  LocationResult,
  LocationSearchResult,
  PricingResponse,
  Ride,
  ScoreMode,
  VehicleCategoryFilter
} from '../types';
import {
  geocodeLocation,
  fetchOSRMRoute,
  fetchPricingEstimate,
  fetchLocationSuggestions,
  reverseGeocode,
  KNOWN_DESTINATIONS
} from '../services/pricingService';
import { storageService } from '../services/storageService';

interface HomeScreenProps {
  onLogout: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onLogout }) => {
  // Location States (Default: Nagpur central transit route)
  const [fromAddress, setFromAddress] = useState('Nagpur Railway Station');
  const [toAddress, setToAddress] = useState('Nagpur Airport');

  const [originCoord, setOriginCoord] = useState<LocationCoordinate | null>({
    latitude: 21.1524,
    longitude: 79.0887
  });

  const [destinationCoord, setDestinationCoord] = useState<LocationCoordinate | null>({
    latitude: 21.0922,
    longitude: 79.0474
  });

  const [routeCoords, setRouteCoords] = useState<LocationCoordinate[]>([]);
  const [totalDistance, setTotalDistance] = useState('8.45 km');
  const [totalDuration, setTotalDuration] = useState('22 minutes');
  const [routeError, setRouteError] = useState<string | null>(null);

  // Asynchronous race-condition guard
  const activeRequestIdRef = useRef<number>(0);

  // Comparison & Pricing states
  const [isLoadingRoute, setIsLoadingRoute] = useState(false);
  const [isFindingRides, setIsFindingRides] = useState(false);
  const [pricingData, setPricingData] = useState<PricingResponse | null>(null);
  const [isComparisonOpen, setIsComparisonOpen] = useState(false);

  // Autocomplete / Suggestions
  const [fromSuggestionsOpen, setFromSuggestionsOpen] = useState(false);
  const [toSuggestionsOpen, setToSuggestionsOpen] = useState(false);
  const [fromSuggestions, setFromSuggestions] = useState<LocationSearchResult[]>([]);
  const [toSuggestions, setToSuggestions] = useState<LocationSearchResult[]>([]);
  const [isLoadingFromSuggestions, setIsLoadingFromSuggestions] = useState(false);
  const [isLoadingToSuggestions, setIsLoadingToSuggestions] = useState(false);
  const [isLocatingUser, setIsLocatingUser] = useState(false);

  // Preference mode
  const [activeMode, setActiveMode] = useState<ScoreMode>(() => {
    const profile = storageService.getUserProfile();
    return profile?.preferences?.mode || 'balanced';
  });

  // Category filter (Mini, Sedan, XL, Auto, all)
  const [selectedCategory, setSelectedCategory] = useState<VehicleCategoryFilter>('all');

  // Modals
  const [isExplorerOpen, setIsExplorerOpen] = useState(false);
  const [isKaroSafeOpen, setIsKaroSafeOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [isPriceAlertOpen, setIsPriceAlertOpen] = useState(false);
  const [selectedRideForAlert, setSelectedRideForAlert] = useState<Ride | null>(null);

  const renderPlaceIcon = (type?: string, isPickup = true) => {
    switch (type) {
      case 'school':
      case 'college':
      case 'institute':
        return <GraduationCap className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />;
      case 'hospital':
      case 'clinic':
        return <HeartPulse className="h-4 w-4 text-rose-600 shrink-0 mt-0.5" />;
      case 'railway_station':
        return <Train className="h-4 w-4 text-amber-600 shrink-0 mt-0.5" />;
      case 'airport':
        return <Plane className="h-4 w-4 text-sky-600 shrink-0 mt-0.5" />;
      case 'postal_area':
        return <Mail className="h-4 w-4 text-purple-600 shrink-0 mt-0.5" />;
      case 'square':
        return <Navigation className="h-4 w-4 text-orange-600 shrink-0 mt-0.5" />;
      case 'business':
        return <Store className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />;
      default:
        return isPickup ? (
          <MapPin className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
        ) : (
          <Flag className="h-4 w-4 text-red-500 shrink-0 mt-0.5" />
        );
    }
  };

  // Debounced input search for Pickup
  useEffect(() => {
    const clean = fromAddress.trim();
    if (!clean || clean.length < 2) {
      setFromSuggestions([]);
      return;
    }
    const timer = setTimeout(async () => {
      setIsLoadingFromSuggestions(true);
      try {
        const results = (await fetchLocationSuggestions(clean, {
          mapCenter: originCoord || { latitude: 21.1458, longitude: 79.0882 }
        })) as unknown as LocationSearchResult[];
        setFromSuggestions(results);
      } catch {
        setFromSuggestions([]);
      } finally {
        setIsLoadingFromSuggestions(false);
      }
    }, 320);
    return () => clearTimeout(timer);
  }, [fromAddress]);

  // Debounced input search for Destination
  useEffect(() => {
    const clean = toAddress.trim();
    if (!clean || clean.length < 2) {
      setToSuggestions([]);
      return;
    }
    const timer = setTimeout(async () => {
      setIsLoadingToSuggestions(true);
      try {
        const results = (await fetchLocationSuggestions(clean, {
          mapCenter: originCoord || { latitude: 21.1458, longitude: 79.0882 }
        })) as unknown as LocationSearchResult[];
        setToSuggestions(results);
      } catch {
        setToSuggestions([]);
      } finally {
        setIsLoadingToSuggestions(false);
      }
    }, 320);
    return () => clearTimeout(timer);
  }, [toAddress]);

  const handleUseCurrentLocation = () => {
    if (!navigator.geolocation) {
      setRouteError('Geolocation is not supported by your browser.');
      return;
    }

    setIsLocatingUser(true);
    setRouteError(null);

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const { latitude, longitude } = pos.coords;
        try {
          const rev = await reverseGeocode(latitude, longitude);
          const displayName = rev.displayName || `Current Location (${latitude.toFixed(4)}, ${longitude.toFixed(4)})`;
          setFromAddress(displayName);
          const newOrigin: LocationCoordinate = { latitude, longitude };
          setOriginCoord(newOrigin);
          setIsLocatingUser(false);
          if (toAddress.trim()) {
            executeRouteSearch(displayName, toAddress, false, newOrigin, destinationCoord);
          }
        } catch {
          const fallbackOrigin: LocationCoordinate = { latitude, longitude };
          setFromAddress(`Current Location (${latitude.toFixed(4)}, ${longitude.toFixed(4)})`);
          setOriginCoord(fallbackOrigin);
          setIsLocatingUser(false);
          if (toAddress.trim()) {
            executeRouteSearch('Current Location', toAddress, false, fallbackOrigin, destinationCoord);
          }
        }
      },
      (err) => {
        setIsLocatingUser(false);
        setRouteError(
          err.code === 1
            ? 'GPS location access denied. Please grant location permissions.'
            : 'Unable to retrieve your current GPS coordinates.'
        );
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  };

  /**
   * Unified route search and calculation pipeline
   * Ensures that:
   * 1. Old route and markers are immediately cleared.
   * 2. Current text inputs are geocoded to accurate coordinates (or uses explicit selected coords).
   * 3. A new route is computed and polyline/distance/duration updated.
   * 4. Fares are updated according to the new distance.
   * 5. Map viewport fits both pickup and drop-off accurately.
   * 6. Asynchronous race-conditions are prevented via request IDs.
   */
  const executeRouteSearch = async (
    targetFrom: string,
    targetTo: string,
    openComparison = false,
    explicitOrigin?: LocationCoordinate | null,
    explicitDest?: LocationCoordinate | null
  ) => {
    const cleanFrom = targetFrom.trim();
    const cleanTo = targetTo.trim();

    if (!cleanFrom || !cleanTo) {
      setRouteError('Please enter both pickup and destination locations.');
      return;
    }

    const currentReqId = ++activeRequestIdRef.current;

    // Reset old route, distance, and error states immediately before calculation
    setRouteError(null);
    setIsLoadingRoute(true);
    setIsFindingRides(true);
    setRouteCoords([]);
    if (!explicitOrigin) setOriginCoord(null);
    if (!explicitDest) setDestinationCoord(null);

    try {
      // Step 1: Geocode current pickup & destination or use explicit coords
      const origin = explicitOrigin || (await geocodeLocation(cleanFrom));
      if (currentReqId !== activeRequestIdRef.current) return;
      setOriginCoord({ latitude: origin.latitude, longitude: origin.longitude });

      const destination = explicitDest || (await geocodeLocation(cleanTo));
      if (currentReqId !== activeRequestIdRef.current) return;
      setDestinationCoord({ latitude: destination.latitude, longitude: destination.longitude });

      if (!origin || !destination) {
        throw new Error('Unable to find coordinates for the given locations.');
      }

      // Step 2: Fetch new route geometry & metrics from OSRM
      const route = await fetchOSRMRoute(origin, destination);

      if (currentReqId !== activeRequestIdRef.current) return;

      setRouteCoords(route.coordinates);
      setTotalDistance(`${route.distanceKm.toFixed(2)} km`);
      setTotalDuration(`${route.durationMinutes} minutes`);

      // Step 3: Re-calculate fare comparison based on updated route
      const estimate = await fetchPricingEstimate(
        route.distanceKm,
        route.durationMinutes,
        activeMode
      );

      if (currentReqId !== activeRequestIdRef.current) return;

      setPricingData(estimate);
      setIsLoadingRoute(false);
      setIsFindingRides(false);

      if (openComparison) {
        setIsComparisonOpen(true);
      }
    } catch (err: any) {
      if (currentReqId === activeRequestIdRef.current) {
        setRouteCoords([]);
        setPricingData(null);
        setTotalDistance('--');
        setTotalDuration('--');
        setRouteError(
          err?.message || 'Could not calculate route between these locations. Please check the spelling.'
        );
        setIsLoadingRoute(false);
        setIsFindingRides(false);
      }
    }
  };

  // Run initial route computation once on mount for demo
  useEffect(() => {
    executeRouteSearch(fromAddress, toAddress, false);
  }, []);

  const handleSwapLocations = () => {
    const nextFrom = toAddress;
    const nextTo = fromAddress;
    const nextOrigin = destinationCoord;
    const nextDest = originCoord;
    setFromAddress(nextFrom);
    setToAddress(nextTo);
    setOriginCoord(nextOrigin);
    setDestinationCoord(nextDest);
    executeRouteSearch(nextFrom, nextTo, false, nextOrigin, nextDest);
  };

  const handleSelectQuickDest = (destName: string) => {
    setToAddress(destName);
    setDestinationCoord(null);
    executeRouteSearch(fromAddress, destName, false, originCoord, null);
  };

  const handleSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setFromSuggestionsOpen(false);
    setToSuggestionsOpen(false);
    executeRouteSearch(fromAddress, toAddress, true, originCoord, destinationCoord);
  };

  const handleOpenPriceAlert = (ride: Ride) => {
    setSelectedRideForAlert(ride);
    setIsPriceAlertOpen(true);
  };

  const handleRefreshFares = async () => {
    await executeRouteSearch(fromAddress, toAddress, false, originCoord, destinationCoord);
  };

  const landmarkNames = Object.keys(KNOWN_DESTINATIONS).map((k) =>
    k.charAt(0).toUpperCase() + k.slice(1)
  );

  return (
    <div className="flex h-screen w-full flex-col lg:flex-row bg-[#FBFBFB] overflow-hidden">
      {/* ======================================================== */}
      {/* SIDEBAR PANEL (Desktop) / TOP CONTROLS (Mobile)         */}
      {/* ======================================================== */}
      <aside className="z-30 flex flex-col w-full lg:w-[460px] xl:w-[480px] bg-white border-r border-gray-200/80 shadow-xl shrink-0 h-auto lg:h-full overflow-hidden">
        {/* App Top Bar */}
        <header className="flex h-16 items-center justify-between border-b border-gray-150 px-4 sm:px-6 bg-white shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-blue-600 text-white font-black shadow-xs">
              <Car className="h-5 w-5" />
            </div>
            <div>
              <h1 className="text-xl font-black text-gray-950 tracking-tight leading-none">
                KaroCab
              </h1>
              <span className="text-[10px] font-bold text-blue-600 tracking-wide uppercase">
                Mobility Intelligence
              </span>
            </div>
          </div>

          <div className="flex items-center gap-1">
            <button
              onClick={() => setIsChatOpen(true)}
              title="KaroAI"
              className="flex h-10 w-10 items-center justify-center rounded-xl text-blue-600 hover:bg-blue-50 transition"
            >
              <MessageSquare className="h-5 w-5" />
            </button>
            <button
              onClick={() => setIsExplorerOpen(true)}
              title="Destination Explorer"
              className="flex h-10 w-10 items-center justify-center rounded-xl text-gray-600 hover:bg-gray-100 transition"
            >
              <Compass className="h-5 w-5" />
            </button>
            <button
              onClick={() => setIsKaroSafeOpen(true)}
              title="KaroSafe SOS"
              className="flex h-10 w-10 items-center justify-center rounded-xl text-red-600 hover:bg-red-50 transition"
            >
              <ShieldAlert className="h-5 w-5" />
            </button>
            <button
              onClick={() => setIsProfileOpen(true)}
              title="My Profile"
              className="flex h-10 w-10 items-center justify-center rounded-xl text-gray-600 hover:bg-gray-100 transition"
            >
              <User className="h-5 w-5" />
            </button>
          </div>
        </header>

        {/* Inputs & Search Section */}
        <div className="p-4 sm:p-5 border-b border-gray-150 bg-slate-50/50 space-y-3 shrink-0">
          <form onSubmit={handleSubmit} className="space-y-2.5 relative">
            {/* Pickup (From) */}
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-emerald-600">
                <MapPin className="h-4 w-4" />
              </div>
              <input
                type="text"
                value={fromAddress}
                onFocus={() => setFromSuggestionsOpen(true)}
                onChange={(e) => {
                  setFromAddress(e.target.value);
                  setOriginCoord(null);
                  setRouteError(null);
                  setFromSuggestionsOpen(true);
                }}
                placeholder="Where From? (Pickup location or address)"
                className="w-full rounded-2xl border border-gray-200 bg-white py-3 pl-10 pr-16 text-xs font-bold text-gray-950 placeholder:text-gray-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20 shadow-2xs"
              />
              <div className="absolute inset-y-0 right-0 pr-2 flex items-center gap-1">
                <button
                  type="button"
                  onClick={handleUseCurrentLocation}
                  disabled={isLocatingUser}
                  title="Use Current GPS Location"
                  className="p-1.5 rounded-lg text-emerald-600 hover:bg-emerald-50 active:bg-emerald-100 transition disabled:opacity-50"
                >
                  {isLocatingUser ? (
                    <div className="h-3.5 w-3.5 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <LocateFixed className="h-3.5 w-3.5" />
                  )}
                </button>
                <button
                  type="button"
                  onClick={handleSwapLocations}
                  title="Swap Locations"
                  className="p-1.5 rounded-lg text-gray-400 hover:text-blue-600 transition"
                >
                  <ArrowUpDown className="h-3.5 w-3.5" />
                </button>
              </div>

              {/* Suggestions popup */}
              {fromSuggestionsOpen && (
                <div className="absolute left-0 right-0 top-full mt-1 z-40 max-h-56 overflow-y-auto rounded-2xl bg-white border border-gray-200 shadow-xl p-1.5 space-y-1 animate-in fade-in zoom-in-95 duration-150">
                  <div className="flex justify-between items-center px-2 py-1 text-[10px] font-bold text-gray-400 uppercase">
                    <span>
                      {isLoadingFromSuggestions
                        ? 'Searching Real Places...'
                        : fromSuggestions.length > 0
                        ? 'Suggested Pickups'
                        : 'Popular Pickups'}
                    </span>
                    <button
                      type="button"
                      onClick={() => setFromSuggestionsOpen(false)}
                      className="text-gray-500 hover:text-gray-900"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </div>
                  {fromSuggestions.length > 0 ? (
                    fromSuggestions.map((item, idx) => (
                      <button
                        key={`from-sug-${idx}`}
                        type="button"
                        onClick={() => {
                          const chosen = item.name || item.displayName;
                          setFromAddress(chosen);
                          const coord = { latitude: item.latitude, longitude: item.longitude };
                          setOriginCoord(coord);
                          setFromSuggestionsOpen(false);
                          if (destinationCoord || toAddress) {
                            executeRouteSearch(chosen, toAddress, false, coord, destinationCoord);
                          }
                        }}
                        className="w-full text-left px-2.5 py-2 rounded-xl hover:bg-blue-50 text-xs font-semibold text-gray-800 transition flex items-start gap-2.5 cursor-pointer"
                      >
                        {renderPlaceIcon(item.type, true)}
                        <div className="min-w-0 flex-1">
                          <div className="font-bold text-gray-950 truncate flex items-center gap-1.5">
                            <span>{item.name || item.displayName.split(',')[0]}</span>
                          </div>
                          <div className="text-[11px] text-gray-500 truncate font-normal">
                            {[item.locality, item.city, item.state].filter(Boolean).join(', ') || item.displayName}
                          </div>
                        </div>
                        <span className="text-[9px] uppercase px-1.5 py-0.5 rounded bg-gray-100 text-gray-700 font-bold shrink-0 self-center">
                          {item.category || (item.type ? item.type.replace('_', ' ') : item.city || 'Place')}
                        </span>
                      </button>
                    ))
                  ) : (
                    landmarkNames.slice(0, 6).map((name) => (
                      <button
                        key={'from-' + name}
                        type="button"
                        onClick={() => {
                          setFromAddress(name);
                          setOriginCoord(null);
                          setFromSuggestionsOpen(false);
                          executeRouteSearch(name, toAddress, false, null, destinationCoord);
                        }}
                        className="w-full text-left px-2.5 py-1.5 rounded-xl hover:bg-blue-50 text-xs font-semibold text-gray-800 transition flex items-center gap-2"
                      >
                        <MapPin className="h-3.5 w-3.5 text-emerald-600 shrink-0" />
                        <span className="truncate">{name}</span>
                      </button>
                    ))
                  )}
                </div>
              )}
            </div>

            {/* Destination (To) */}
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-red-500">
                <Flag className="h-4 w-4" />
              </div>
              <input
                type="text"
                value={toAddress}
                onFocus={() => setToSuggestionsOpen(true)}
                onChange={(e) => {
                  setToAddress(e.target.value);
                  setDestinationCoord(null);
                  setRouteError(null);
                  setToSuggestionsOpen(true);
                }}
                placeholder="Where To? (Destination location or local address)"
                className="w-full rounded-2xl border border-gray-200 bg-white py-3 pl-10 pr-4 text-xs font-bold text-gray-950 placeholder:text-gray-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20 shadow-2xs"
              />

              {/* Suggestions popup */}
              {toSuggestionsOpen && (
                <div className="absolute left-0 right-0 top-full mt-1 z-40 max-h-56 overflow-y-auto rounded-2xl bg-white border border-gray-200 shadow-xl p-1.5 space-y-1 animate-in fade-in zoom-in-95 duration-150">
                  <div className="flex justify-between items-center px-2 py-1 text-[10px] font-bold text-gray-400 uppercase">
                    <span>
                      {isLoadingToSuggestions
                        ? 'Searching Real Places...'
                        : toSuggestions.length > 0
                        ? 'Suggested Destinations'
                        : 'Popular Destinations'}
                    </span>
                    <button
                      type="button"
                      onClick={() => setToSuggestionsOpen(false)}
                      className="text-gray-500 hover:text-gray-900"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </div>
                  {toSuggestions.length > 0 ? (
                    toSuggestions.map((item, idx) => (
                      <button
                        key={`to-sug-${idx}`}
                        type="button"
                        onClick={() => {
                          const chosen = item.name || item.displayName;
                          setToAddress(chosen);
                          const coord = { latitude: item.latitude, longitude: item.longitude };
                          setDestinationCoord(coord);
                          setToSuggestionsOpen(false);
                          executeRouteSearch(fromAddress, chosen, false, originCoord, coord);
                        }}
                        className="w-full text-left px-2.5 py-2 rounded-xl hover:bg-blue-50 text-xs font-semibold text-gray-800 transition flex items-start gap-2.5 cursor-pointer"
                      >
                        {renderPlaceIcon(item.type, false)}
                        <div className="min-w-0 flex-1">
                          <div className="font-bold text-gray-950 truncate flex items-center gap-1.5">
                            <span>{item.name || item.displayName.split(',')[0]}</span>
                          </div>
                          <div className="text-[11px] text-gray-500 truncate font-normal">
                            {[item.locality, item.city, item.state].filter(Boolean).join(', ') || item.displayName}
                          </div>
                        </div>
                        <span className="text-[9px] uppercase px-1.5 py-0.5 rounded bg-gray-100 text-gray-700 font-bold shrink-0 self-center">
                          {item.category || (item.type ? item.type.replace('_', ' ') : item.city || 'Place')}
                        </span>
                      </button>
                    ))
                  ) : (
                    landmarkNames.slice(0, 6).map((name) => (
                      <button
                        key={'to-' + name}
                        type="button"
                        onClick={() => {
                          setToAddress(name);
                          setDestinationCoord(null);
                          setToSuggestionsOpen(false);
                          executeRouteSearch(fromAddress, name, false, originCoord, null);
                        }}
                        className="w-full text-left px-2.5 py-1.5 rounded-xl hover:bg-blue-50 text-xs font-semibold text-gray-800 transition flex items-center gap-2"
                      >
                        <Flag className="h-3.5 w-3.5 text-red-500 shrink-0" />
                        <span className="truncate">{name}</span>
                      </button>
                    ))
                  )}
                </div>
              )}
            </div>

              {/* Submit Action Button */}
              <button
                type="submit"
                disabled={isFindingRides || isLoadingRoute}
                className="flex w-full items-center justify-center gap-2 rounded-2xl py-3.5 text-sm font-black text-white shadow-lg shadow-blue-500/25 transition active:scale-[0.98] disabled:opacity-60 cursor-pointer"
                style={{
                  background: 'linear-gradient(to bottom, #0152FF, #0693FF)'
                }}
              >
                {isFindingRides || isLoadingRoute ? (
                  <div className="flex items-center gap-2">
                    <div className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Calculating route & fares...</span>
                  </div>
                ) : (
                  <>
                    <Search className="h-4 w-4" />
                    <span>Compare Cab & Auto Fares</span>
                  </>
                )}
              </button>
            </form>

            {/* Error Notification Pill */}
            {routeError && (
              <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-xs font-bold text-red-700 flex items-center justify-between animate-in fade-in duration-200">
                <span>⚠️ {routeError}</span>
                <button
                  type="button"
                  onClick={() => setRouteError(null)}
                  className="text-red-500 hover:text-red-800 p-0.5"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
            )}

          {/* Quick Route Status Pill */}
          <div className="flex items-center justify-between text-xs font-bold text-gray-700 bg-white p-2.5 rounded-xl border border-gray-200/80 shadow-2xs">
            <span className="flex items-center gap-1.5">
              <Car className="h-3.5 w-3.5 text-blue-600" />
              <span>Route: {isLoadingRoute ? 'Calculating...' : routeError ? 'Unavailable' : totalDistance}</span>
            </span>
            <span className="flex items-center gap-1 text-gray-500">
              <Clock className="h-3.5 w-3.5" />
              <span>Est. {isLoadingRoute ? 'Calculating...' : routeError ? '--' : totalDuration}</span>
            </span>
            <button
              onClick={() => setIsComparisonOpen(true)}
              className="text-blue-600 hover:text-blue-800 text-[11px] font-extrabold flex items-center gap-0.5"
            >
              <span>View All</span>
              <ChevronRight className="h-3 w-3" />
            </button>
          </div>
        </div>

        {/* Desktop Sidebar Rides Feed */}
        <div className="hidden lg:flex flex-1 flex-col overflow-y-auto p-4 sm:p-5 space-y-3.5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-extrabold text-gray-800 uppercase tracking-wide">
              Top Recommendations
            </span>
            <span className="text-[11px] font-semibold text-blue-600">
              Mode: {activeMode.toUpperCase()}
            </span>
          </div>

          {pricingData?.rides ? (
            <div className="space-y-3">
              <CategoryFilter
                selectedCategory={selectedCategory}
                onSelectCategory={setSelectedCategory}
                rides={pricingData.rides}
                compact
              />

              <div
                key={`sidebar-${selectedCategory}-${pricingData.farePrediction.currentFare}`}
                className="space-y-2 transition-all duration-300"
              >
                {(selectedCategory === 'all'
                  ? pricingData.rides
                  : pricingData.rides.filter((r) => r.vehicleCategory === selectedCategory)
                ).map((ride, idx) => (
                  <RideCard
                    key={'sidebar-' + ride.id + '-' + selectedCategory}
                    ride={ride}
                    index={idx}
                    onSelect={() => setIsComparisonOpen(true)}
                    pickupCoord={originCoord}
                    dropCoord={destinationCoord}
                    pickupAddress={fromAddress}
                    dropAddress={toAddress}
                  />
                ))}
              </div>
            </div>
          ) : (
            <div className="py-10 text-center text-xs text-gray-400">
              Enter locations to view live comparisons
            </div>
          )}
        </div>
      </aside>

      {/* ======================================================== */}
      {/* EXPANSIVE INTERACTIVE MAP VIEW                          */}
      {/* ======================================================== */}
      <main className="relative flex-1 h-full w-full bg-slate-100 overflow-hidden">
        <MapView
          origin={originCoord}
          destination={destinationCoord}
          routeCoordinates={routeCoords}
          isLoadingRoute={isLoadingRoute}
          routeError={routeError}
          originLabel={fromAddress}
          destinationLabel={toAddress}
        />

        {/* Floating Quick Landmarks Bar */}
        <div className="absolute top-4 left-4 right-4 z-20 flex items-center gap-2 overflow-x-auto no-scrollbar pointer-events-auto">
          {['Railway Station', 'Airport', 'Sitabuldi', 'Futala Lake', 'Deekshabhoomi'].map((hub) => (
            <button
              key={hub}
              onClick={() => handleSelectQuickDest(hub)}
              className="shrink-0 flex items-center gap-1.5 rounded-full bg-white/95 px-3.5 py-2 text-xs font-extrabold text-gray-800 shadow-md backdrop-blur-md hover:bg-blue-50 hover:text-blue-600 transition border border-gray-150 cursor-pointer active:scale-95"
            >
              <MapPin className="h-3 w-3 text-blue-600" />
              <span>{hub}</span>
            </button>
          ))}
        </div>

        {/* Floating Compare Button for Mobile View */}
        <div className="lg:hidden absolute bottom-5 left-4 right-4 z-20">
          <button
            onClick={() => setIsComparisonOpen(true)}
            className="flex w-full items-center justify-center gap-2 rounded-2xl bg-gray-950/95 backdrop-blur-md text-white py-3.5 text-sm font-extrabold shadow-xl hover:bg-black transition active:scale-[0.98]"
          >
            <Layers className="h-4 w-4 text-blue-400" />
            <span>Open Ride Comparison Sheet ({pricingData?.rides.length || 4} options)</span>
          </button>
        </div>
      </main>

      {/* ======================================================== */}
      {/* MODALS & PANELS                                          */}
      {/* ======================================================== */}
      <ComparisonModal
        isOpen={isComparisonOpen}
        onClose={() => setIsComparisonOpen(false)}
        pricingData={pricingData}
        fromAddress={fromAddress}
        toAddress={toAddress}
        originCoord={originCoord}
        destinationCoord={destinationCoord}
        onSetPriceAlert={handleOpenPriceAlert}
        initialCategory={selectedCategory}
        onRefreshFares={handleRefreshFares}
        isRefreshing={isFindingRides}
      />

      <DestinationExplorerModal
        isOpen={isExplorerOpen}
        onClose={() => setIsExplorerOpen(false)}
        onSelectDestination={handleSelectQuickDest}
      />

      <KaroSafeModal
        isOpen={isKaroSafeOpen}
        onClose={() => setIsKaroSafeOpen(false)}
      />

      <PriceAlertModal
        isOpen={isPriceAlertOpen}
        onClose={() => setIsPriceAlertOpen(false)}
        rides={pricingData?.rides || []}
        fromAddress={fromAddress}
        toAddress={toAddress}
        distance={pricingData?.distance}
        duration={pricingData?.duration}
        initialSelectedRide={selectedRideForAlert}
      />

      <ProfileModal
        isOpen={isProfileOpen}
        onClose={() => setIsProfileOpen(false)}
        onLogout={onLogout}
      />

      <ChatScreenModal
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        pricingContext={pricingData}
        fromAddress={fromAddress}
        toAddress={toAddress}
      />
    </div>
  );
};
