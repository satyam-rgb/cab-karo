/**
 * KaroCab Shared Business Domain Contracts
 * Single Source of Truth for Web (TypeScript) and Mobile (Flutter/Dart).
 */

export type ScoreMode = 'budget' | 'hurry' | 'balanced';

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

export interface RouteGeometry {
  coordinates: LocationCoordinate[];
  distanceKm: number;
  durationMinutes: number;
  isLiveRoute: boolean;
  routeSource: 'osrm_live' | 'routing_fallback';
  notice?: string;
}

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

export interface Ride {
  id: string;
  provider: 'Uber' | 'Ola' | string;
  category: string;
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

export interface SmartRecommendations {
  bestOverall: string | null;
  bestBudget: string | null;
  cheapest: string | null;
  fastest: string | null;
  safest: string | null;
  budgetButNotSlowest: string | null;
  balanced: string | null;
  explanations?: Record<string, string | undefined>;
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
  scoreMode?: ScoreMode;
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

export interface EmergencyContact {
  name: string;
  phone: string;
}
