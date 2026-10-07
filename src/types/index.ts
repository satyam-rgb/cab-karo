export interface RideScores {
  price: number;
  eta: number;
  duration: number;
  safety: number;
  comfort: number;
  reliability: number;
}

export interface RideScoreWeights {
  price: number;
  eta: number;
  duration: number;
  safety: number;
  comfort: number;
  reliability: number;
}

export interface ScoreExplanationFactor {
  name: string;
  score: number;
  weight: number;
  contribution: number;
}

export interface ScoreExplanation {
  summary: string;
  strongestFactor: string;
  strongestFactorScore: number;
  factors: Record<string, ScoreExplanationFactor>;
}

export type VehicleCategory = 'Auto' | 'Mini' | 'Sedan' | 'XL';
export type VehicleCategoryFilter = 'all' | VehicleCategory;

export interface Ride {
  id: string;
  provider: 'Uber' | 'Ola' | string;
  category: 'Cab' | 'Auto' | 'Mini' | 'Sedan' | 'XL' | string;
  vehicleCategory?: VehicleCategory | string;
  capacity?: number;
  fare: number;
  eta: number;
  duration: number;
  comfort: number;
  reliability: number;
  safety: number;
  karoScore: number;
  dataSource?: 'real_api' | 'demo_estimate';
  scores?: RideScores;
  scoreWeights?: RideScoreWeights;
  explanation?: ScoreExplanation;
  highlights?: ('bestOverall' | 'cheapest' | 'fastest' | 'safest')[];
}

export interface RegressionMetrics {
  mae: number;
  rmse: number;
  r2: number;
}

export interface FarePrediction {
  predictedFare: number;
  currentFare: number;
  expectedChange: number;
  expectedChangePercent: number;
  trend: 'up' | 'down' | 'stable';
  recommendation: 'Book Now' | 'Consider Waiting' | 'Either option is reasonable' | string;
  model: string;
  dataType: string;
  metrics?: RegressionMetrics;
}

export interface Tradeoffs {
  budgetButNotSlowest?: {
    extraCostComparedWithCheapest?: number;
    timeSavedComparedWithSlowest?: number;
  };
  extraCostVsBudget?: string | number;
  timeSavedVsSlowest?: string | number;
}

export interface SmartRecommendations {
  bestOverall: string | null;
  bestBudget: string | null; // Cheapest
  cheapest: string | null;
  fastest: string | null;
  safest: string | null;
  budgetButNotSlowest: string | null;
  balanced: string | null;
  preference?: string | null;
  explanations?: {
    bestOverall?: string;
    bestBudget?: string;
    cheapest?: string;
    fastest?: string;
    safest?: string;
    budgetButNotSlowest?: string;
    balanced?: string;
    [key: string]: string | undefined;
  };
  tradeoffs?: Tradeoffs;
  budgetButNotSlowestExplanation?: string;
  balancedExplanation?: string;
}

export interface PricingResponse {
  source?: string;
  dataSource?: 'real_api' | 'demo_estimate';
  pricingNotice?: string;
  isLiveRoute?: boolean;
  routeSource?: 'osrm_live' | 'routing_fallback';
  distance: number;
  duration: number;
  rides: Ride[];
  recommendations: SmartRecommendations;
  tradeoffs?: Tradeoffs;
  farePrediction: FarePrediction;
  scoreMode?: 'budget' | 'hurry' | 'balanced';
  recommendationModel?: {
    balancedWeights: {
      price: number;
      speed: number;
      karoScore: number;
    };
    note: string;
  };
}

export interface PriceAlert {
  id: string;
  status: 'active' | 'triggered' | 'dismissed';
  provider: string;
  category: string;
  currentFare: number;
  targetPrice: number;
  from: string;
  to: string;
  distance?: number;
  duration?: number;
  createdAt: string;
}

export type ScoreMode = 'budget' | 'hurry' | 'balanced';

export interface UserPreferences {
  mode: ScoreMode;
  comfort: boolean;
}

export interface UserProfile {
  phone: string;
  monthlyBudget: number;
  preferences: UserPreferences;
  createdAt: string;
  lastLoginAt: string;
}

export interface Expense {
  id: string;
  provider: string;
  category: string;
  amount: number;
  type: string;
  createdAt: string; // ISO date string
}

export interface EmergencyContact {
  name: string;
  phone: string;
}

export interface LocationCoordinate {
  latitude: number;
  longitude: number;
}

export type LocationPlaceType =
  | 'address'
  | 'locality'
  | 'neighbourhood'
  | 'road'
  | 'school'
  | 'college'
  | 'hospital'
  | 'clinic'
  | 'institute'
  | 'business'
  | 'landmark'
  | 'square'
  | 'railway_station'
  | 'airport'
  | 'postal_area'
  | 'poi';

export interface LocationSearchResult {
  id: string;
  name: string;
  displayName: string;
  latitude: number;
  longitude: number;
  type: LocationPlaceType;
  category?: string;
  locality?: string;
  city?: string;
  district?: string;
  state?: string;
  postalCode?: string;
  source: 'nominatim' | 'photon' | 'overpass' | 'google_places' | 'local_gazetteer' | 'postal_service';
  confidence: number;
  rawAddress?: string;
}

export interface LocationResult {
  query: string;
  displayName: string;
  latitude: number;
  longitude: number;
  city?: string;
  state?: string;
  source: string;
  confidence?: number;
  placeType?: LocationPlaceType;
}
