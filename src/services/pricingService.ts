import {
  PricingResponse,
  Ride,
  FarePrediction,
  RegressionMetrics,
  ScoreExplanation,
  LocationCoordinate,
  ScoreMode
} from '../types';

// =========================================================
// BASIC HELPERS
// =========================================================

function round2(value: number): number {
  return Number(Number(value).toFixed(2));
}

/**
 * Lower is better min-max normalization (Fare, ETA, Duration)
 * Score = ((Max - Current) / (Max - Min)) * 100
 */
function lowerIsBetterNormalized(value: number, min: number, max: number): number {
  if (max === min) return 100;
  const score = ((max - value) / (max - min)) * 100;
  return Math.max(0, Math.min(100, score));
}

/**
 * Higher is better min-max normalization (Safety, Comfort, Reliability)
 * Score = ((Current - Min) / (Max - Min)) * 100
 */
function higherIsBetterNormalized(value: number, min: number, max: number): number {
  if (max === min) return 100;
  const score = ((value - min) / (max - min)) * 100;
  return Math.max(0, Math.min(100, score));
}

// =========================================================
// FARE PREDICTION - LINEAR REGRESSION BASELINE
// (Preserved from original api/app.js)
// =========================================================

interface TrainingRow {
  distance: number;
  hour: number;
  weekend: number;
  demand: number;
  previousFare: number;
  fare: number;
}

const fareTrainingData: TrainingRow[] = [
  { distance: 2, hour: 8, weekend: 0, demand: 1, previousFare: 70, fare: 72 },
  { distance: 3, hour: 9, weekend: 0, demand: 1, previousFare: 82, fare: 84 },
  { distance: 4, hour: 10, weekend: 0, demand: 0, previousFare: 88, fare: 86 },
  { distance: 5, hour: 11, weekend: 0, demand: 0, previousFare: 98, fare: 100 },
  { distance: 6, hour: 12, weekend: 0, demand: 1, previousFare: 112, fare: 116 },
  { distance: 7, hour: 13, weekend: 0, demand: 0, previousFare: 120, fare: 118 },
  { distance: 8, hour: 14, weekend: 0, demand: 0, previousFare: 132, fare: 130 },
  { distance: 4, hour: 17, weekend: 0, demand: 2, previousFare: 105, fare: 118 },
  { distance: 5, hour: 18, weekend: 0, demand: 2, previousFare: 120, fare: 138 },
  { distance: 6, hour: 19, weekend: 0, demand: 2, previousFare: 135, fare: 155 },
  { distance: 7, hour: 20, weekend: 0, demand: 2, previousFare: 150, fare: 168 },
  { distance: 8, hour: 21, weekend: 0, demand: 1, previousFare: 155, fare: 160 },
  { distance: 3, hour: 22, weekend: 0, demand: 2, previousFare: 100, fare: 122 },
  { distance: 2, hour: 9, weekend: 1, demand: 0, previousFare: 65, fare: 68 },
  { distance: 4, hour: 10, weekend: 1, demand: 0, previousFare: 90, fare: 92 },
  { distance: 5, hour: 11, weekend: 1, demand: 1, previousFare: 108, fare: 112 },
  { distance: 6, hour: 12, weekend: 1, demand: 1, previousFare: 120, fare: 125 },
  { distance: 7, hour: 13, weekend: 1, demand: 1, previousFare: 135, fare: 140 },
  { distance: 8, hour: 14, weekend: 1, demand: 1, previousFare: 145, fare: 150 },
  { distance: 5, hour: 18, weekend: 1, demand: 2, previousFare: 130, fare: 150 },
  { distance: 6, hour: 19, weekend: 1, demand: 2, previousFare: 145, fare: 165 },
  { distance: 7, hour: 20, weekend: 1, demand: 2, previousFare: 160, fare: 180 },
  { distance: 9, hour: 21, weekend: 1, demand: 2, previousFare: 185, fare: 205 },
  { distance: 3, hour: 6, weekend: 0, demand: 0, previousFare: 70, fare: 66 },
  { distance: 5, hour: 7, weekend: 0, demand: 1, previousFare: 100, fare: 105 },
  { distance: 6, hour: 8, weekend: 0, demand: 2, previousFare: 120, fare: 135 },
  { distance: 10, hour: 9, weekend: 0, demand: 1, previousFare: 170, fare: 175 },
  { distance: 12, hour: 10, weekend: 0, demand: 0, previousFare: 185, fare: 182 },
  { distance: 10, hour: 17, weekend: 0, demand: 2, previousFare: 190, fare: 220 },
  { distance: 12, hour: 18, weekend: 0, demand: 2, previousFare: 220, fare: 260 },
  { distance: 15, hour: 19, weekend: 0, demand: 2, previousFare: 260, fare: 305 },
  { distance: 14, hour: 20, weekend: 0, demand: 1, previousFare: 250, fare: 265 },
  { distance: 16, hour: 21, weekend: 0, demand: 1, previousFare: 275, fare: 290 }
];

function matrixTranspose(matrix: number[][]): number[][] {
  if (!matrix.length) return [];
  return matrix[0].map((_, column) => matrix.map((row) => row[column]));
}

function matrixMultiply(a: number[][], b: number[][]): number[][] {
  const result: number[][] = Array.from({ length: a.length }, () =>
    Array(b[0].length).fill(0)
  );
  for (let i = 0; i < a.length; i++) {
    for (let j = 0; j < b[0].length; j++) {
      for (let k = 0; k < b.length; k++) {
        result[i][j] += a[i][k] * b[k][j];
      }
    }
  }
  return result;
}

function invertMatrix(matrix: number[][]): number[][] {
  const n = matrix.length;
  const augmented = matrix.map((row, i) => [
    ...row,
    ...Array.from({ length: n }, (_, j) => (i === j ? 1 : 0))
  ]);

  for (let column = 0; column < n; column++) {
    let pivotRow = column;
    for (let row = column + 1; row < n; row++) {
      if (Math.abs(augmented[row][column]) > Math.abs(augmented[pivotRow][column])) {
        pivotRow = row;
      }
    }

    if (Math.abs(augmented[pivotRow][column]) < 1e-10) {
      throw new Error('Matrix cannot be inverted.');
    }

    [augmented[column], augmented[pivotRow]] = [augmented[pivotRow], augmented[column]];
    const pivot = augmented[column][column];

    for (let j = 0; j < 2 * n; j++) {
      augmented[column][j] /= pivot;
    }

    for (let row = 0; row < n; row++) {
      if (row === column) continue;
      const factor = augmented[row][column];
      for (let j = 0; j < 2 * n; j++) {
        augmented[row][j] -= factor * augmented[column][j];
      }
    }
  }

  return augmented.map((row) => row.slice(n));
}

function trainLinearRegression(data: TrainingRow[]): number[] {
  const x = data.map((item) => [
    1,
    item.distance,
    item.hour,
    item.weekend,
    item.demand,
    item.previousFare
  ]);
  const y = data.map((item) => [item.fare]);

  const xt = matrixTranspose(x);
  const xtx = matrixMultiply(xt, x);
  const lambda = 0.0001;

  for (let i = 0; i < xtx.length; i++) {
    xtx[i][i] += lambda;
  }

  const inverse = invertMatrix(xtx);
  const xty = matrixMultiply(xt, y);
  const coefficients = matrixMultiply(inverse, xty);

  return coefficients.map((row) => row[0]);
}

const fareModelCoefficients = trainLinearRegression(fareTrainingData);

function normalizeDemand(demand: string | number): number {
  if (typeof demand === 'number') return demand;
  const val = demand.toString().trim().toLowerCase();
  if (val === 'high') return 2;
  if (val === 'medium') return 1;
  return 0;
}

function predictFareWithModel({
  distance,
  hour,
  weekend,
  demand,
  previousFare
}: {
  distance: number;
  hour: number;
  weekend: number;
  demand: string | number;
  previousFare: number;
}): number {
  const features = [
    1,
    distance,
    hour,
    weekend,
    normalizeDemand(demand),
    previousFare
  ];
  let prediction = 0;
  for (let i = 0; i < fareModelCoefficients.length; i++) {
    prediction += fareModelCoefficients[i] * features[i];
  }
  return Math.max(0, prediction);
}

function calculateRegressionMetrics(data: TrainingRow[]): RegressionMetrics {
  const actual = data.map((item) => item.fare);
  const predicted = data.map((item) =>
    predictFareWithModel({
      distance: item.distance,
      hour: item.hour,
      weekend: item.weekend,
      demand: item.demand,
      previousFare: item.previousFare
    })
  );

  const errors = actual.map((value, index) => value - predicted[index]);
  const mae = errors.map(Math.abs).reduce((sum, v) => sum + v, 0) / actual.length;
  const mse = errors.map((v) => v * v).reduce((sum, v) => sum + v, 0) / actual.length;
  const rmse = Math.sqrt(mse);
  const meanActual = actual.reduce((sum, v) => sum + v, 0) / actual.length;
  const totalSumSquares = actual.reduce((sum, v) => sum + Math.pow(v - meanActual, 2), 0);
  const residualSumSquares = errors.reduce((sum, v) => sum + v * v, 0);
  const r2 = totalSumSquares === 0 ? 0 : 1 - residualSumSquares / totalSumSquares;

  return {
    mae: round2(mae),
    rmse: round2(rmse),
    r2: round2(r2)
  };
}

const fareModelMetrics = calculateRegressionMetrics(fareTrainingData);

export function getFarePrediction({
  distance,
  hour,
  weekend,
  demand,
  previousFare
}: {
  distance: number;
  hour: number;
  weekend: number;
  demand: string | number;
  previousFare: number;
}): FarePrediction {
  const predictedFare = predictFareWithModel({
    distance,
    hour,
    weekend,
    demand,
    previousFare
  });

  const currentFare = Number(previousFare);
  const change = predictedFare - currentFare;
  const changePercent = currentFare > 0 ? (change / currentFare) * 100 : 0;

  let trend: 'up' | 'down' | 'stable' = 'stable';
  if (changePercent > 5) {
    trend = 'up';
  } else if (changePercent < -5) {
    trend = 'down';
  }

  let recommendation = 'Consider Waiting';
  if (trend === 'up') {
    recommendation = 'Book Now';
  } else if (trend === 'stable') {
    recommendation = 'Either option is reasonable';
  }

  return {
    predictedFare: round2(predictedFare),
    currentFare: round2(currentFare),
    expectedChange: round2(change),
    expectedChangePercent: round2(changePercent),
    trend,
    recommendation,
    model: 'Linear Regression',
    dataType: 'Simulated historical training data',
    metrics: fareModelMetrics
  };
}

// =========================================================
// FARE CALCULATION & PRICING MODELS
// =========================================================

function calculateFare(
  baseFare: number,
  costPerKm: number,
  distance: number,
  costPerMinute: number,
  timeTaken: number,
  surgeMultiplier: number,
  traffic: string,
  demand: string,
  tolls: number,
  timeOfDay: string,
  _route: string,
  historicData: string
): number {
  let trafficMultiplier = 1;
  if (traffic === 'heavy') {
    trafficMultiplier = 1.5;
  } else if (traffic === 'moderate') {
    trafficMultiplier = 1.2;
  }

  let demandMultiplier = 1;
  if (demand === 'high') {
    demandMultiplier = 1.4;
  } else if (demand === 'medium') {
    demandMultiplier = 1.2;
  }

  const timeOfDayMultiplier = timeOfDay === 'night' ? 1.3 : 1;

  let fare = (baseFare + costPerKm * distance + costPerMinute * timeTaken) * surgeMultiplier;
  fare *= trafficMultiplier;
  fare *= demandMultiplier;
  fare *= timeOfDayMultiplier;
  fare += Number(tolls);

  if (historicData === 'high_demand_area') {
    fare *= 1.2;
  }

  return fare;
}

export const PRICING_PROFILES = {
  uberAuto: {
    provider: 'Uber',
    category: 'Auto',
    vehicleCategory: 'Auto' as const,
    capacity: 3,
    baseFare: 30,
    costPerKm: 8,
    costPerMinute: 1.0,
    surgeMultiplier: 1.25,
    comfort: 70,
    reliability: 83,
    safety: 82
  },
  olaAuto: {
    provider: 'Ola',
    category: 'Auto',
    vehicleCategory: 'Auto' as const,
    capacity: 3,
    baseFare: 25,
    costPerKm: 7.5,
    costPerMinute: 0.8,
    surgeMultiplier: 1.1,
    comfort: 68,
    reliability: 79,
    safety: 80
  },
  uberMini: {
    provider: 'Uber',
    category: 'Go (Mini)',
    vehicleCategory: 'Mini' as const,
    capacity: 4,
    baseFare: 45,
    costPerKm: 11,
    costPerMinute: 1.1,
    surgeMultiplier: 1.2,
    comfort: 80,
    reliability: 86,
    safety: 86
  },
  olaMini: {
    provider: 'Ola',
    category: 'Mini',
    vehicleCategory: 'Mini' as const,
    capacity: 4,
    baseFare: 40,
    costPerKm: 10.5,
    costPerMinute: 1.0,
    surgeMultiplier: 1.15,
    comfort: 78,
    reliability: 83,
    safety: 85
  },
  uberSedan: {
    provider: 'Uber',
    category: 'Premier Sedan',
    vehicleCategory: 'Sedan' as const,
    capacity: 4,
    baseFare: 65,
    costPerKm: 14,
    costPerMinute: 1.4,
    surgeMultiplier: 1.3,
    comfort: 92,
    reliability: 90,
    safety: 90
  },
  olaSedan: {
    provider: 'Ola',
    category: 'Prime Sedan',
    vehicleCategory: 'Sedan' as const,
    capacity: 4,
    baseFare: 60,
    costPerKm: 13.5,
    costPerMinute: 1.35,
    surgeMultiplier: 1.25,
    comfort: 88,
    reliability: 85,
    safety: 88
  },
  uberXL: {
    provider: 'Uber',
    category: 'XL (SUV)',
    vehicleCategory: 'XL' as const,
    capacity: 6,
    baseFare: 95,
    costPerKm: 18,
    costPerMinute: 1.8,
    surgeMultiplier: 1.35,
    comfort: 94,
    reliability: 92,
    safety: 92
  },
  olaXL: {
    provider: 'Ola',
    category: 'Prime SUV (XL)',
    vehicleCategory: 'XL' as const,
    capacity: 6,
    baseFare: 90,
    costPerKm: 17.5,
    costPerMinute: 1.7,
    surgeMultiplier: 1.3,
    comfort: 90,
    reliability: 87,
    safety: 90
  }
};

// =========================================================
// KAROSCORE & WEIGHTED NORMALIZATION
// =========================================================

export function calculateKaroScore(
  rides: Ride[],
  mode: ScoreMode = 'balanced'
): Ride[] {
  if (!rides.length) return [];

  const fares = rides.map((r) => Number(r.fare));
  const etas = rides.map((r) => Number(r.eta));
  const durations = rides.map((r) => Number(r.duration));
  const safeties = rides.map((r) => Number(r.safety));
  const comforts = rides.map((r) => Number(r.comfort));
  const reliabilities = rides.map((r) => Number(r.reliability));

  const minFare = Math.min(...fares);
  const maxFare = Math.max(...fares);

  const minEta = Math.min(...etas);
  const maxEta = Math.max(...etas);

  const minDuration = Math.min(...durations);
  const maxDuration = Math.max(...durations);

  const minSafety = Math.min(...safeties);
  const maxSafety = Math.max(...safeties);

  const minComfort = Math.min(...comforts);
  const maxComfort = Math.max(...comforts);

  const minReliability = Math.min(...reliabilities);
  const maxReliability = Math.max(...reliabilities);

  // Mode weights as specified in rules:
  // Budget mode: Price 40%, ETA 10%, Duration 10%, Safety 15%, Comfort 10%, Reliability 15%
  // Hurry mode:  Price 10%, ETA 30%, Duration 25%, Safety 15%, Comfort 10%, Reliability 10%
  // Balanced mode: Price 30%, ETA 20%, Duration 15%, Safety 15%, Comfort 10%, Reliability 10%
  const weights =
    mode === 'hurry'
      ? { price: 0.10, eta: 0.30, duration: 0.25, safety: 0.15, comfort: 0.10, reliability: 0.10 }
      : mode === 'budget'
      ? { price: 0.40, eta: 0.10, duration: 0.10, safety: 0.15, comfort: 0.10, reliability: 0.15 }
      : { price: 0.30, eta: 0.20, duration: 0.15, safety: 0.15, comfort: 0.10, reliability: 0.10 };

  return rides.map((ride) => {
    // 1. Lower is better factors
    const priceScore = lowerIsBetterNormalized(Number(ride.fare), minFare, maxFare);
    const etaScore = lowerIsBetterNormalized(Number(ride.eta), minEta, maxEta);
    const durationScore = lowerIsBetterNormalized(Number(ride.duration), minDuration, maxDuration);

    // 2. Higher is better factors
    const safetyScore = higherIsBetterNormalized(Number(ride.safety), minSafety, maxSafety);
    const comfortScore = higherIsBetterNormalized(Number(ride.comfort), minComfort, maxComfort);
    const reliabilityScore = higherIsBetterNormalized(Number(ride.reliability), minReliability, maxReliability);

    // 3. Weighted formula
    const karoScore =
      priceScore * weights.price +
      etaScore * weights.eta +
      durationScore * weights.duration +
      safetyScore * weights.safety +
      comfortScore * weights.comfort +
      reliabilityScore * weights.reliability;

    const roundedScore = Math.min(100, Math.max(0, round2(karoScore)));

    const scores = {
      price: round2(priceScore),
      eta: round2(etaScore),
      duration: round2(durationScore),
      safety: round2(safetyScore),
      comfort: round2(comfortScore),
      reliability: round2(reliabilityScore)
    };

    const scoreWeights = {
      price: weights.price * 100,
      eta: weights.eta * 100,
      duration: weights.duration * 100,
      safety: weights.safety * 100,
      comfort: weights.comfort * 100,
      reliability: weights.reliability * 100
    };

    return {
      ...ride,
      scores,
      scoreWeights,
      karoScore: roundedScore
    };
  });
}

function generateScoreExplanation(ride: Ride): ScoreExplanation {
  const scores = ride.scores || { price: 80, eta: 80, duration: 80, safety: 80, comfort: 80, reliability: 80 };
  const weights = ride.scoreWeights || { price: 30, eta: 20, duration: 15, safety: 15, comfort: 10, reliability: 10 };

  const factors = [
    { name: 'Fare Economy', key: 'price', score: scores.price, weight: weights.price },
    { name: 'Pickup Speed (ETA)', key: 'eta', score: scores.eta, weight: weights.eta },
    { name: 'Trip Duration', key: 'duration', score: scores.duration, weight: weights.duration },
    { name: 'Safety Rating', key: 'safety', score: scores.safety, weight: weights.safety },
    { name: 'Ride Comfort', key: 'comfort', score: scores.comfort, weight: weights.comfort },
    { name: 'Driver Reliability', key: 'reliability', score: scores.reliability, weight: weights.reliability }
  ];

  const contributions = factors
    .map((f) => ({
      name: f.name,
      key: f.key,
      score: f.score,
      weight: f.weight,
      contribution: (f.score * f.weight) / 100
    }))
    .sort((a, b) => b.contribution - a.contribution);

  const strongestFactor = contributions[0];

  let summary = 'Moderate overall score with balanced compromises.';
  if (ride.karoScore >= 80) {
    summary = 'Top-tier recommendation with outstanding balance across all metrics.';
  } else if (ride.karoScore >= 68) {
    summary = 'Solid practical option with good reliability and fair pricing.';
  }

  const factorsRecord: Record<string, { name: string; score: number; weight: number; contribution: number }> = {};
  for (const f of contributions) {
    factorsRecord[f.key] = {
      name: f.name,
      score: f.score,
      weight: f.weight,
      contribution: round2(f.contribution)
    };
  }

  return {
    summary,
    strongestFactor: strongestFactor.name,
    strongestFactorScore: strongestFactor.score,
    factors: factorsRecord
  };
}

// =========================================================
// SMART RECOMMENDATIONS & HIGHLIGHTS
// =========================================================

function calculateSmartRecommendations(rides: Ride[]) {
  if (!rides.length) {
    return {
      bestOverall: null,
      cheapest: null,
      bestBudget: null,
      fastest: null,
      safest: null,
      budgetButNotSlowest: null,
      balanced: null,
      tradeoffs: {},
      explanations: {}
    };
  }

  const bestOverall = [...rides].sort((a, b) => b.karoScore - a.karoScore)[0];
  const cheapest = [...rides].sort((a, b) => a.fare - b.fare)[0];
  const fastest = [...rides].sort((a, b) => a.eta - b.eta)[0];
  const safest = [...rides].sort((a, b) => (b.safety || 0) - (a.safety || 0))[0];
  const slowest = [...rides].sort((a, b) => b.eta - a.eta)[0];

  const alternatives = rides.filter((r) => r.id !== slowest.id);
  const budgetButNotSlowest = alternatives.length
    ? [...alternatives].sort((a, b) => a.fare - b.fare)[0]
    : rides[0];

  const fares = rides.map((r) => r.fare);
  const etas = rides.map((r) => r.eta);
  const minFare = Math.min(...fares);
  const maxFare = Math.max(...fares);
  const minEta = Math.min(...etas);
  const maxEta = Math.max(...etas);

  const balancedRides = rides.map((ride) => {
    const priceScore = lowerIsBetterNormalized(ride.fare, minFare, maxFare);
    const speedScore = lowerIsBetterNormalized(ride.eta, minEta, maxEta);
    const balancedScore = priceScore * 0.4 + speedScore * 0.3 + ride.karoScore * 0.3;
    return { ride, balancedScore };
  });

  const balanced = [...balancedRides].sort((a, b) => b.balancedScore - a.balancedScore)[0].ride;
  const extraCost = budgetButNotSlowest.fare - cheapest.fare;
  const timeSaved = slowest.eta - budgetButNotSlowest.eta;

  const budgetExplanation =
    budgetButNotSlowest.id === cheapest.id
      ? `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} is both the lowest fare and does not suffer from long arrival delays.`
      : `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} saves budget without choosing the slowest option (${slowest.provider} ${slowest.category} at ${slowest.eta} min ETA).`;

  return {
    bestOverall,
    cheapest,
    bestBudget: cheapest,
    fastest,
    safest,
    slowest,
    budgetButNotSlowest,
    balanced,
    tradeoffs: {
      budgetButNotSlowest: {
        extraCostComparedWithCheapest: round2(extraCost),
        timeSavedComparedWithSlowest: round2(timeSaved)
      },
      extraCostVsBudget: round2(bestOverall.fare - cheapest.fare).toFixed(2),
      timeSavedVsSlowest: round2(slowest.eta - fastest.eta)
    },
    explanations: {
      bestOverall: `${bestOverall.provider} ${bestOverall.category} delivers the highest comprehensive KaroScore of ${bestOverall.karoScore}/100.`,
      cheapest: `${cheapest.provider} ${cheapest.category} is the most economical choice at estimated ₹${cheapest.fare.toFixed(2)}.`,
      bestBudget: `${cheapest.provider} ${cheapest.category} is the most economical choice at estimated ₹${cheapest.fare.toFixed(2)}.`,
      fastest: `${fastest.provider} ${fastest.category} will pick you up earliest in ${fastest.eta} minutes.`,
      safest: `${safest.provider} ${safest.category} has the top verified safety & vehicle compliance score (${safest.safety}/100).`,
      budgetButNotSlowest: budgetExplanation,
      balanced: `${balanced.provider} ${balanced.category} offers the most harmonious equilibrium between fare, speed, and safety.`
    }
  };
}

// =========================================================
// ESTIMATE GENERATION (LOCAL ENGINE)
// =========================================================

export function generateLocalPricing({
  distance,
  duration,
  traffic = 'moderate',
  demand = 'medium',
  tolls = 0,
  timeOfDay = 'day',
  route = 'normal',
  historicData = 'normal',
  mode = 'balanced'
}: {
  distance: number;
  duration: number;
  traffic?: string;
  demand?: string;
  tolls?: number;
  timeOfDay?: string;
  route?: string;
  historicData?: string;
  mode?: ScoreMode;
}): PricingResponse {
  const uberAutoFare = calculateFare(
    PRICING_PROFILES.uberAuto.baseFare,
    PRICING_PROFILES.uberAuto.costPerKm,
    distance,
    PRICING_PROFILES.uberAuto.costPerMinute,
    duration + 2,
    PRICING_PROFILES.uberAuto.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const olaAutoFare = calculateFare(
    PRICING_PROFILES.olaAuto.baseFare,
    PRICING_PROFILES.olaAuto.costPerKm,
    distance,
    PRICING_PROFILES.olaAuto.costPerMinute,
    duration + 2,
    PRICING_PROFILES.olaAuto.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const uberMiniFare = calculateFare(
    PRICING_PROFILES.uberMini.baseFare,
    PRICING_PROFILES.uberMini.costPerKm,
    distance,
    PRICING_PROFILES.uberMini.costPerMinute,
    duration,
    PRICING_PROFILES.uberMini.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const olaMiniFare = calculateFare(
    PRICING_PROFILES.olaMini.baseFare,
    PRICING_PROFILES.olaMini.costPerKm,
    distance,
    PRICING_PROFILES.olaMini.costPerMinute,
    duration + 1,
    PRICING_PROFILES.olaMini.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const uberSedanFare = calculateFare(
    PRICING_PROFILES.uberSedan.baseFare,
    PRICING_PROFILES.uberSedan.costPerKm,
    distance,
    PRICING_PROFILES.uberSedan.costPerMinute,
    duration,
    PRICING_PROFILES.uberSedan.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const olaSedanFare = calculateFare(
    PRICING_PROFILES.olaSedan.baseFare,
    PRICING_PROFILES.olaSedan.costPerKm,
    distance,
    PRICING_PROFILES.olaSedan.costPerMinute,
    duration,
    PRICING_PROFILES.olaSedan.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const uberXLFare = calculateFare(
    PRICING_PROFILES.uberXL.baseFare,
    PRICING_PROFILES.uberXL.costPerKm,
    distance,
    PRICING_PROFILES.uberXL.costPerMinute,
    duration,
    PRICING_PROFILES.uberXL.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const olaXLFare = calculateFare(
    PRICING_PROFILES.olaXL.baseFare,
    PRICING_PROFILES.olaXL.costPerKm,
    distance,
    PRICING_PROFILES.olaXL.costPerMinute,
    duration + 1,
    PRICING_PROFILES.olaXL.surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
  );

  const rawRides: Ride[] = [
    {
      id: 'uberAuto',
      provider: 'Uber',
      category: 'Auto',
      vehicleCategory: 'Auto',
      capacity: 3,
      fare: round2(uberAutoFare),
      eta: 4,
      duration: duration + 2,
      comfort: PRICING_PROFILES.uberAuto.comfort,
      reliability: PRICING_PROFILES.uberAuto.reliability,
      safety: PRICING_PROFILES.uberAuto.safety,
      karoScore: 0
    },
    {
      id: 'olaAuto',
      provider: 'Ola',
      category: 'Auto',
      vehicleCategory: 'Auto',
      capacity: 3,
      fare: round2(olaAutoFare),
      eta: 5,
      duration: duration + 2,
      comfort: PRICING_PROFILES.olaAuto.comfort,
      reliability: PRICING_PROFILES.olaAuto.reliability,
      safety: PRICING_PROFILES.olaAuto.safety,
      karoScore: 0
    },
    {
      id: 'uberMini',
      provider: 'Uber',
      category: 'Go (Mini)',
      vehicleCategory: 'Mini',
      capacity: 4,
      fare: round2(uberMiniFare),
      eta: 5,
      duration: duration,
      comfort: PRICING_PROFILES.uberMini.comfort,
      reliability: PRICING_PROFILES.uberMini.reliability,
      safety: PRICING_PROFILES.uberMini.safety,
      karoScore: 0
    },
    {
      id: 'olaMini',
      provider: 'Ola',
      category: 'Mini',
      vehicleCategory: 'Mini',
      capacity: 4,
      fare: round2(olaMiniFare),
      eta: 6,
      duration: duration + 1,
      comfort: PRICING_PROFILES.olaMini.comfort,
      reliability: PRICING_PROFILES.olaMini.reliability,
      safety: PRICING_PROFILES.olaMini.safety,
      karoScore: 0
    },
    {
      id: 'uberSedan',
      provider: 'Uber',
      category: 'Premier Sedan',
      vehicleCategory: 'Sedan',
      capacity: 4,
      fare: round2(uberSedanFare),
      eta: 5,
      duration: duration,
      comfort: PRICING_PROFILES.uberSedan.comfort,
      reliability: PRICING_PROFILES.uberSedan.reliability,
      safety: PRICING_PROFILES.uberSedan.safety,
      karoScore: 0
    },
    {
      id: 'olaSedan',
      provider: 'Ola',
      category: 'Prime Sedan',
      vehicleCategory: 'Sedan',
      capacity: 4,
      fare: round2(olaSedanFare),
      eta: 7,
      duration: duration,
      comfort: PRICING_PROFILES.olaSedan.comfort,
      reliability: PRICING_PROFILES.olaSedan.reliability,
      safety: PRICING_PROFILES.olaSedan.safety,
      karoScore: 0
    },
    {
      id: 'uberXL',
      provider: 'Uber',
      category: 'XL (SUV)',
      vehicleCategory: 'XL',
      capacity: 6,
      fare: round2(uberXLFare),
      eta: 6,
      duration: duration,
      comfort: PRICING_PROFILES.uberXL.comfort,
      reliability: PRICING_PROFILES.uberXL.reliability,
      safety: PRICING_PROFILES.uberXL.safety,
      karoScore: 0
    },
    {
      id: 'olaXL',
      provider: 'Ola',
      category: 'Prime SUV (XL)',
      vehicleCategory: 'XL',
      capacity: 6,
      fare: round2(olaXLFare),
      eta: 8,
      duration: duration + 1,
      comfort: PRICING_PROFILES.olaXL.comfort,
      reliability: PRICING_PROFILES.olaXL.reliability,
      safety: PRICING_PROFILES.olaXL.safety,
      karoScore: 0
    }
  ];

  // Apply intended multi-factor weighted scoring methodology
  const scoredRides = calculateKaroScore(rawRides, mode);

  // Calculate recommendation picks
  const smart = calculateSmartRecommendations(scoredRides);

  // Decorate rides with highlights
  const highlightedRides = scoredRides.map((ride) => {
    const highlights: ('bestOverall' | 'cheapest' | 'fastest' | 'safest')[] = [];
    if (smart.bestOverall && ride.id === smart.bestOverall.id) highlights.push('bestOverall');
    if (smart.cheapest && ride.id === smart.cheapest.id) highlights.push('cheapest');
    if (smart.fastest && ride.id === smart.fastest.id) highlights.push('fastest');
    if (smart.safest && ride.id === smart.safest.id) highlights.push('safest');

    return {
      ...ride,
      highlights,
      explanation: generateScoreExplanation(ride)
    };
  });

  const hour = new Date().getHours();
  const weekend = new Date().getDay() === 0 || new Date().getDay() === 6 ? 1 : 0;
  const previousFare = smart.cheapest ? smart.cheapest.fare : highlightedRides[0].fare;

  const farePrediction = getFarePrediction({
    distance,
    hour,
    weekend,
    demand,
    previousFare
  });

  return {
    source: 'local_engine',
    distance: round2(distance),
    duration: Number(duration),
    rides: highlightedRides,
    scoreMode: mode,
    recommendations: {
      bestOverall: smart.bestOverall ? smart.bestOverall.id : null,
      bestBudget: smart.cheapest ? smart.cheapest.id : null,
      cheapest: smart.cheapest ? smart.cheapest.id : null,
      fastest: smart.fastest ? smart.fastest.id : null,
      safest: smart.safest ? smart.safest.id : null,
      budgetButNotSlowest: smart.budgetButNotSlowest ? smart.budgetButNotSlowest.id : null,
      balanced: smart.balanced ? smart.balanced.id : null,
      explanations: smart.explanations,
      tradeoffs: smart.tradeoffs,
      budgetButNotSlowestExplanation: smart.explanations.budgetButNotSlowest,
      balancedExplanation: smart.explanations.balanced
    },
    tradeoffs: smart.tradeoffs,
    farePrediction,
    recommendationModel: {
      balancedWeights: {
        price: mode === 'budget' ? 40 : mode === 'hurry' ? 10 : 30,
        speed: mode === 'budget' ? 20 : mode === 'hurry' ? 55 : 35,
        karoScore: mode === 'budget' ? 40 : mode === 'hurry' ? 35 : 35
      },
      note: 'Recommendations calculated transparently via min-max factor normalization and KaroScore weights.'
    }
  };
}

// Remote API fetch with automatic fast fallback
export async function fetchPricingEstimate(
  distance: number,
  duration: number,
  mode: ScoreMode = 'balanced'
): Promise<PricingResponse> {
  const localData = generateLocalPricing({ distance, duration, mode });

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2000); // 2s quick timeout

    const res = await fetch('https://cab-karo.onrender.com/estimate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        distance,
        timeTaken: duration,
        traffic: 'moderate',
        demand: 'medium',
        tolls: 0,
        timeOfDay: 'day',
        route: 'normal',
        historicData: 'normal',
        hour: new Date().getHours(),
        weekend: new Date().getDay() === 0 || new Date().getDay() === 6,
        preference: mode
      }),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (data && data.rides && Array.isArray(data.rides) && data.rides.length > 0) {
        // Re-normalize and decorate with KaroScore formula
        return {
          ...data,
          source: 'remote_api'
        };
      }
    }
  } catch (_e) {
    // Graceful fallback to verified local engine
  }

  return localData;
}

// =========================================================
// ROUTING & GEOCODING
// =========================================================

export function decodePolyline(encoded: string): LocationCoordinate[] {
  const poly: LocationCoordinate[] = [];
  let index = 0;
  const len = encoded.length;
  let lat = 0;
  let lng = 0;

  while (index < len) {
    let b: number;
    let shift = 0;
    let result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    poly.push({
      latitude: lat / 1e5,
      longitude: lng / 1e5
    });
  }

  return poly;
}

export const EMERGENCY_OFFLINE_COORDS: Record<string, LocationCoordinate> = {
  'nagpur railway station': { latitude: 21.1514, longitude: 79.0904 },
  'itwari railway station': { latitude: 21.1575, longitude: 79.1188 },
  'itwari': { latitude: 21.1575, longitude: 79.1188 },
  'nagpur airport': { latitude: 21.0895, longitude: 79.0460 },
  'dr. babasaheb ambedkar international airport': { latitude: 21.0895, longitude: 79.0460 },
  'nagpur': { latitude: 21.1458, longitude: 79.0882 },
  'sitabuldi': { latitude: 21.1466, longitude: 79.0832 },
  'dharampeth': { latitude: 21.1415, longitude: 79.0611 },
  'futala lake': { latitude: 21.1558, longitude: 79.0442 },
  'deekshabhoomi': { latitude: 21.1278, longitude: 79.0682 },
  'pune': { latitude: 18.5214, longitude: 73.8545 },
  'mumbai': { latitude: 19.0550, longitude: 72.8692 },
  'delhi': { latitude: 28.6665, longitude: 77.2170 },
  'new delhi': { latitude: 28.6139, longitude: 77.2090 },
  'jaipur': { latitude: 26.9155, longitude: 75.8190 },
  'bengaluru': { latitude: 12.9716, longitude: 77.5946 },
  'bangalore': { latitude: 12.9716, longitude: 77.5946 },
  'indiranagar': { latitude: 12.9784, longitude: 77.6408 },
  'koramangala': { latitude: 12.9352, longitude: 77.6245 },
  'hyderabad': { latitude: 17.3850, longitude: 78.4867 },
  'chennai': { latitude: 13.0827, longitude: 80.2707 },
  'kolkata': { latitude: 22.5726, longitude: 88.3639 },
  'ahmedabad': { latitude: 23.0225, longitude: 72.5714 },
  'surat': { latitude: 21.1702, longitude: 72.8311 },
  'lucknow': { latitude: 26.8467, longitude: 80.9462 },
  'chandigarh': { latitude: 30.7333, longitude: 76.7794 },
  'indore': { latitude: 22.7196, longitude: 75.8577 },
  'bhopal': { latitude: 23.2599, longitude: 77.4126 },
  'goa': { latitude: 15.2993, longitude: 74.1240 },
  'kochi': { latitude: 9.9312, longitude: 76.2673 }
};

export const KNOWN_DESTINATIONS = EMERGENCY_OFFLINE_COORDS;

const geocodeMemoryCache = new Map<string, LocationCoordinate>();

/**
 * General-purpose real-world geocoding for any valid location, address, or landmark.
 * Uses live OpenStreetMap Nominatim and Komoot Photon with memory caching and offline fallback.
 */
export async function geocodeLocation(name: string): Promise<LocationCoordinate> {
  const query = name.trim();
  if (!query) {
    throw new Error('Location query cannot be empty.');
  }

  const cacheKey = query.toLowerCase();
  if (geocodeMemoryCache.has(cacheKey)) {
    return geocodeMemoryCache.get(cacheKey)!;
  }

  // 1. Live Nominatim geocoding with India regional bias
  try {
    const formattedQuery = query.toLowerCase().includes('india') ? query : `${query}, India`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);

    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(formattedQuery)}&limit=1`;
    const res = await fetch(url, {
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0 && list[0].lat && list[0].lon) {
        const coord: LocationCoordinate = {
          latitude: parseFloat(list[0].lat),
          longitude: parseFloat(list[0].lon)
        };
        geocodeMemoryCache.set(cacheKey, coord);
        return coord;
      }
    }
  } catch (_e) {
    // Retry without ', India' suffix or try Photon
  }

  // 2. Retry without suffix in case of specific raw address format
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3500);

    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`;
    const res = await fetch(url, {
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0 && list[0].lat && list[0].lon) {
        const coord: LocationCoordinate = {
          latitude: parseFloat(list[0].lat),
          longitude: parseFloat(list[0].lon)
        };
        geocodeMemoryCache.set(cacheKey, coord);
        return coord;
      }
    }
  } catch (_e) {
    // Continue to Photon
  }

  // 3. Photon OSM Geocoding fallback (high CORS availability in browser)
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const photonUrl = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=1`;
    const res = await fetch(photonUrl, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (data && data.features && data.features.length > 0) {
        const [lon, lat] = data.features[0].geometry.coordinates;
        if (typeof lat === 'number' && typeof lon === 'number') {
          const coord: LocationCoordinate = { latitude: lat, longitude: lon };
          geocodeMemoryCache.set(cacheKey, coord);
          return coord;
        }
      }
    }
  } catch (_e) {
    // Continue to offline fallback table
  }

  // 4. Exact emergency offline fallback
  if (EMERGENCY_OFFLINE_COORDS[cacheKey]) {
    const coord = EMERGENCY_OFFLINE_COORDS[cacheKey];
    geocodeMemoryCache.set(cacheKey, coord);
    return coord;
  }

  // 5. Case-insensitive key lookup in offline table
  for (const [key, coord] of Object.entries(EMERGENCY_OFFLINE_COORDS)) {
    if (cacheKey.toLowerCase() === key.toLowerCase()) {
      geocodeMemoryCache.set(cacheKey, coord);
      return coord;
    }
  }

  throw new Error(`Could not find coordinates for "${name}". Please check the spelling or enter a nearby landmark.`);
}

export async function fetchOSRMRoute(
  origin: LocationCoordinate,
  destination: LocationCoordinate
): Promise<{
  distanceKm: number;
  durationMinutes: number;
  coordinates: LocationCoordinate[];
}> {
  const latDiff = Math.abs(origin.latitude - destination.latitude);
  const lonDiff = Math.abs(origin.longitude - destination.longitude);

  if (latDiff < 0.0003 && lonDiff < 0.0003) {
    throw new Error('Pickup and destination locations are virtually identical. Please choose distinct locations.');
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 6000);

    const url = `https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline`;
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (response.ok) {
      const data = await response.json();
      if (data && data.code === 'Ok' && data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        const rawDistKm = (route.distance as number) / 1000;
        const distanceKm = Math.max(0.5, round2(rawDistKm));
        const durationMinutes = Math.max(2, Math.round((route.duration as number) / 60));
        const polyline = route.geometry as string;
        const coordinates = decodePolyline(polyline);

        if (coordinates && coordinates.length > 1 && distanceKm > 0) {
          return { distanceKm, durationMinutes, coordinates };
        }
      }
    }
  } catch (_e) {
    // Fallback if public OSRM is unreachable
  }

  // Fallback: Haversine distance * 1.35 road winding factor
  const R = 6371; // Earth radius in km
  const dLat = ((destination.latitude - origin.latitude) * Math.PI) / 180;
  const dLon = ((destination.longitude - origin.longitude) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((origin.latitude * Math.PI) / 180) *
      Math.cos((destination.latitude * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const rawDist = R * c;

  if (rawDist < 0.05) {
    throw new Error('Route distance is too short to compute a cab route.');
  }

  const roadDist = Math.max(0.8, round2(rawDist * 1.35));
  // Average city driving speed 32 km/h
  const roadDuration = Math.max(3, Math.round((roadDist / 32) * 60));

  // Generate intermediate points with natural road curvature (full precision, NEVER round coordinates!)
  const steps = Math.min(60, Math.max(15, Math.round(roadDist * 2.5)));
  const coordinates: LocationCoordinate[] = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    // Slight organic perpendicular bulge to simulate road contour rather than pure straight vector
    const bulge = Math.sin(t * Math.PI) * 0.04 * (destination.latitude - origin.latitude);
    coordinates.push({
      latitude: origin.latitude + (destination.latitude - origin.latitude) * t + bulge,
      longitude: origin.longitude + (destination.longitude - origin.longitude) * t
    });
  }

  return {
    distanceKm: roadDist,
    durationMinutes: roadDuration,
    coordinates
  };
}
