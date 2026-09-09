import express, { json } from 'express';

const app = express();

app.use(json());

// =========================================================
// Utility helpers
// =========================================================

function round2(value) {
    return Number(Number(value).toFixed(2));
}

// Lower value is better.
function lowerIsBetterScore(value, min, max) {
    if (max === min) return 100;

    return ((max - value) / (max - min)) * 100;
}

// Higher value is better.
function higherIsBetterScore(value, min, max) {
    if (max === min) return 100;

    return ((value - min) / (max - min)) * 100;
}

function sortByFare(a, b) {
    return a.fare - b.fare;
}

function sortByEta(a, b) {
    return a.eta - b.eta;
}

function sortByKaroScore(a, b) {
    return b.karoScore - a.karoScore;
}

// =========================================================
// FARE PREDICTION - ML BASELINE
// =========================================================
//
// This is a lightweight Linear Regression baseline.
//
// Training data is intentionally simulated historical data.
// It is NOT live provider data.
//
// Features:
// 1. Distance in km
// 2. Hour of day
// 3. Weekend flag
// 4. Demand level
// 5. Previous fare
//
// Target:
// Historical fare
//
// This baseline can later be replaced with a larger real
// historical dataset and Random Forest/XGBoost.
// =========================================================

const fareTrainingData = [
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

function matrixTranspose(matrix) {
    if (!matrix.length) return [];

    return matrix[0].map((_, columnIndex) =>
        matrix.map((row) => row[columnIndex])
    );
}

function matrixMultiply(a, b) {
    const result = Array.from(
        { length: a.length },
        () => Array(b[0].length).fill(0)
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

function invertMatrix(matrix) {
    const n = matrix.length;

    const augmented = matrix.map((row, i) => [
        ...row,
        ...Array.from({ length: n }, (_, j) => (i === j ? 1 : 0))
    ]);

    for (let column = 0; column < n; column++) {
        let pivotRow = column;

        for (let row = column + 1; row < n; row++) {
            if (
                Math.abs(augmented[row][column]) >
                Math.abs(augmented[pivotRow][column])
            ) {
                pivotRow = row;
            }
        }

        if (Math.abs(augmented[pivotRow][column]) < 1e-10) {
            throw new Error('Matrix cannot be inverted.');
        }

        [augmented[column], augmented[pivotRow]] =
            [augmented[pivotRow], augmented[column]];

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

function trainLinearRegression(data) {
    const X = data.map((item) => [
        1,
        item.distance,
        item.hour,
        item.weekend,
        item.demand,
        item.previousFare
    ]);

    const y = data.map((item) => [item.fare]);

    const XT = matrixTranspose(X);

    const XTX = matrixMultiply(XT, X);

    // Small ridge value improves numerical stability.
    const lambda = 0.0001;

    for (let i = 0; i < XTX.length; i++) {
        XTX[i][i] += lambda;
    }

    const XTXInverse = invertMatrix(XTX);

    const XTY = matrixMultiply(XT, y);

    const coefficients = matrixMultiply(
        XTXInverse,
        XTY
    );

    return coefficients.map((row) => row[0]);
}

const fareModelCoefficients =
    trainLinearRegression(fareTrainingData);

function predictFareWithModel({
    distance,
    hour,
    weekend,
    demand,
    previousFare
}) {
    const features = [
        1,
        distance,
        hour,
        weekend,
        demand,
        previousFare
    ];

    let prediction = 0;

    for (let i = 0; i < fareModelCoefficients.length; i++) {
        prediction +=
            fareModelCoefficients[i] * features[i];
    }

    return Math.max(0, prediction);
}

function calculateRegressionMetrics(data) {
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

    const errors = actual.map(
        (value, index) => value - predicted[index]
    );

    const absoluteErrors =
        errors.map((error) => Math.abs(error));

    const squaredErrors =
        errors.map((error) => error * error);

    const mae =
        absoluteErrors.reduce(
            (sum, value) => sum + value,
            0
        ) / actual.length;

    const rmse =
        Math.sqrt(
            squaredErrors.reduce(
                (sum, value) => sum + value,
                0
            ) / actual.length
        );

    const meanActual =
        actual.reduce(
            (sum, value) => sum + value,
            0
        ) / actual.length;

    const totalSumSquares =
        actual.reduce(
            (sum, value) =>
                sum + Math.pow(value - meanActual, 2),
            0
        );

    const residualSumSquares =
        squaredErrors.reduce(
            (sum, value) => sum + value,
            0
        );

    const r2 =
        totalSumSquares === 0
            ? 0
            : 1 -
              residualSumSquares /
                  totalSumSquares;

    return {
        mae: round2(mae),
        rmse: round2(rmse),
        r2: round2(r2)
    };
}

const fareModelMetrics =
    calculateRegressionMetrics(
        fareTrainingData
    );

function normalizeDemand(demand) {
    if (!demand) return 0;

    const value =
        demand.toString().trim().toLowerCase();

    if (value === 'high') return 2;
    if (value === 'medium') return 1;

    return 0;
}

function getFarePrediction({
    distance,
    hour,
    weekend,
    demand,
    previousFare
}) {
    const prediction =
        predictFareWithModel({
            distance,
            hour,
            weekend,
            demand: normalizeDemand(demand),
            previousFare
        });

    const currentFare =
        Number(previousFare);

    const difference =
        prediction - currentFare;

    const percentageChange =
        currentFare > 0
            ? (difference / currentFare) * 100
            : 0;

    let trend = 'stable';

    if (percentageChange > 5) {
        trend = 'up';
    } else if (percentageChange < -5) {
        trend = 'down';
    }

    let recommendation = 'Consider Waiting';

    if (trend === 'up') {
        recommendation = 'Book Now';
    } else if (trend === 'stable') {
        recommendation = 'Either option is reasonable';
    }

    return {
        predictedFare: round2(prediction),

        currentFare: round2(currentFare),

        expectedChange:
            round2(difference),

        expectedChangePercent:
            round2(percentageChange),

        trend,

        recommendation,

        model: 'Linear Regression',

        dataType:
            'Simulated historical training data',

        metrics: fareModelMetrics
    };
}

// =========================================================
// Fare calculation
// =========================================================

function calculateFare(
    baseFare,
    costPerKm,
    distance,
    costPerMinute,
    timeTaken,
    surgeMultiplier,
    traffic,
    demand,
    tolls,
    timeOfDay,
    route,
    historicData
) {
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

    let timeOfDayMultiplier = 1;

    if (timeOfDay === 'night') {
        timeOfDayMultiplier = 1.3;
    }

    let fare =
        (
            baseFare +
            costPerKm * distance +
            costPerMinute * timeTaken
        ) *
        surgeMultiplier;

    fare *= trafficMultiplier;
    fare *= demandMultiplier;
    fare *= timeOfDayMultiplier;

    fare += tolls;

    if (historicData === 'high_demand_area') {
        fare *= 1.2;
    }

    return fare;
}

// =========================================================
// Ride models
// =========================================================

const pricingModels = {
    uberCab: {
        provider: 'Uber',
        category: 'Cab',
        baseFare: 50,
        costPerKm: 12,
        costPerMinute: 1.2,
        surgeMultiplier: 1.5,

        // Demo values only.
        // These are NOT real-world safety/reliability claims.
        comfort: 85,
        reliability: 85,
        safety: 80
    },

    uberAuto: {
        provider: 'Uber',
        category: 'Auto',
        baseFare: 30,
        costPerKm: 8,
        costPerMinute: 1,
        surgeMultiplier: 1.3,

        comfort: 70,
        reliability: 82,
        safety: 80
    },

    olaCab: {
        provider: 'Ola',
        category: 'Cab',
        baseFare: 40,
        costPerKm: 10,
        costPerMinute: 1.5,
        surgeMultiplier: 1.2,

        comfort: 84,
        reliability: 80,
        safety: 80
    },

    olaAuto: {
        provider: 'Ola',
        category: 'Auto',
        baseFare: 25,
        costPerKm: 7,
        costPerMinute: 0.8,
        surgeMultiplier: 1.1,

        comfort: 68,
        reliability: 78,
        safety: 78
    }
};

// =========================================================
// KaroScore calculation
// =========================================================

function calculateKaroScore(rides) {
    const fares = rides.map((ride) => ride.fare);
    const etas = rides.map((ride) => ride.eta);
    const durations = rides.map(
        (ride) => ride.duration
    );

    const minFare = Math.min(...fares);
    const maxFare = Math.max(...fares);

    const minEta = Math.min(...etas);
    const maxEta = Math.max(...etas);

    const minDuration =
        Math.min(...durations);

    const maxDuration =
        Math.max(...durations);

    return rides.map((ride) => {
        const priceScore =
            lowerIsBetterScore(
                ride.fare,
                minFare,
                maxFare
            );

        const etaScore =
            lowerIsBetterScore(
                ride.eta,
                minEta,
                maxEta
            );

        const durationScore =
            lowerIsBetterScore(
                ride.duration,
                minDuration,
                maxDuration
            );

        const comfortScore =
            ride.comfort;

        const reliabilityScore =
            ride.reliability;

        const safetyScore =
            ride.safety;

        const karoScore =
            priceScore * 0.35 +
            etaScore * 0.20 +
            durationScore * 0.15 +
            comfortScore * 0.10 +
            reliabilityScore * 0.10 +
            safetyScore * 0.10;

        return {
            ...ride,

            scores: {
                price: round2(priceScore),
                eta: round2(etaScore),
                duration: round2(durationScore),
                comfort: round2(comfortScore),
                reliability:
                    round2(reliabilityScore),
                safety: round2(safetyScore)
            },

            karoScore: round2(karoScore)
        };
    });
}

// =========================================================
// Explainable KaroScore
// =========================================================

function generateScoreExplanation(ride) {
    const scores = ride.scores;

    const factors = [
        {
            name: 'Price',
            score: scores.price,
            weight: 35
        },
        {
            name: 'ETA',
            score: scores.eta,
            weight: 20
        },
        {
            name: 'Duration',
            score: scores.duration,
            weight: 15
        },
        {
            name: 'Comfort',
            score: scores.comfort,
            weight: 10
        },
        {
            name: 'Reliability',
            score: scores.reliability,
            weight: 10
        },
        {
            name: 'Safety',
            score: scores.safety,
            weight: 10
        }
    ];

    const contributions =
        factors.map((factor) => ({
            name: factor.name,
            score: factor.score,
            weight: factor.weight,
            contribution:
                factor.score *
                (factor.weight / 100)
        }));

    contributions.sort(
        (a, b) =>
            b.contribution -
            a.contribution
    );

    const strongestFactor =
        contributions[0];

    let summary;

    if (ride.karoScore >= 75) {
        summary =
            'Strong overall choice based on the current comparison.';
    } else if (ride.karoScore >= 60) {
        summary =
            'Balanced option with a moderate overall score.';
    } else {
        summary =
            'Lower overall score compared with the other available options.';
    }

    return {
        summary,

        strongestFactor:
            strongestFactor.name,

        strongestFactorScore:
            strongestFactor.score,

        factors: {
            price: {
                score: scores.price,
                weight: 35,
                contribution:
                    round2(
                        scores.price * 0.35
                    )
            },

            eta: {
                score: scores.eta,
                weight: 20,
                contribution:
                    round2(
                        scores.eta * 0.20
                    )
            },

            duration: {
                score: scores.duration,
                weight: 15,
                contribution:
                    round2(
                        scores.duration * 0.15
                    )
            },

            comfort: {
                score: scores.comfort,
                weight: 10,
                contribution:
                    round2(
                        scores.comfort * 0.10
                    )
            },

            reliability: {
                score:
                    scores.reliability,
                weight: 10,
                contribution:
                    round2(
                        scores.reliability *
                        0.10
                    )
            },

            safety: {
                score: scores.safety,
                weight: 10,
                contribution:
                    round2(
                        scores.safety * 0.10
                    )
            }
        }
    };
}

// =========================================================
// SMART RECOMMENDATION ENGINE
// =========================================================

function calculateSmartRecommendations(rides) {
    if (!rides || rides.length === 0) {
        return {
            bestOverall: null,
            bestBudget: null,
            fastest: null,
            budgetButNotSlowest: null,
            balanced: null
        };
    }

    const bestOverall =
        [...rides].sort(
            sortByKaroScore
        )[0];

    const bestBudget =
        [...rides].sort(
            sortByFare
        )[0];

    const fastest =
        [...rides].sort(
            sortByEta
        )[0];

    const slowest =
        [...rides].sort(
            (a, b) =>
                b.eta - a.eta
        )[0];

    let budgetButNotSlowest;

    if (rides.length > 1) {
        const alternatives =
            rides.filter(
                (ride) =>
                    ride.id !== slowest.id
            );

        budgetButNotSlowest =
            [...alternatives].sort(
                sortByFare
            )[0];
    } else {
        budgetButNotSlowest =
            rides[0];
    }

    const fares =
        rides.map(
            (ride) => ride.fare
        );

    const etas =
        rides.map(
            (ride) => ride.eta
        );

    const minFare =
        Math.min(...fares);

    const maxFare =
        Math.max(...fares);

    const minEta =
        Math.min(...etas);

    const maxEta =
        Math.max(...etas);

    const balancedRides =
        rides.map((ride) => {
            const priceScore =
                lowerIsBetterScore(
                    ride.fare,
                    minFare,
                    maxFare
                );

            const speedScore =
                lowerIsBetterScore(
                    ride.eta,
                    minEta,
                    maxEta
                );

            const balancedScore =
                priceScore * 0.40 +
                speedScore * 0.30 +
                ride.karoScore * 0.30;

            return {
                ...ride,

                recommendationScores: {
                    priceScore:
                        round2(priceScore),

                    speedScore:
                        round2(speedScore),

                    balancedScore:
                        round2(
                            balancedScore
                        )
                }
            };
        });

    const balanced =
        [...balancedRides].sort(
            (a, b) =>
                b.recommendationScores
                    .balancedScore -
                a.recommendationScores
                    .balancedScore
        )[0];

    const budgetFare =
        bestBudget.fare;

    const budgetNotSlowestFare =
        budgetButNotSlowest.fare;

    const budgetNotSlowestEta =
        budgetButNotSlowest.eta;

    const slowestEta =
        slowest.eta;

    const extraCost =
        budgetNotSlowestFare -
        budgetFare;

    const timeSaved =
        slowestEta -
        budgetNotSlowestEta;

    const budgetButNotSlowestExplanation =
        budgetButNotSlowest.id ===
        bestBudget.id
            ? `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} is both the cheapest option and not the slowest ride.`
            : `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} is recommended for users who want to save money without choosing the slowest ride. The slowest option is ${slowest.provider} ${slowest.category} at ${slowest.eta} minutes.`;

    const balancedExplanation =
        `${balanced.provider} ${balanced.category} provides the strongest balance of estimated price, ETA and current KaroScore under the balanced recommendation model.`;

    return {
        bestOverall,
        bestBudget,
        fastest,
        slowest,
        budgetButNotSlowest,
        balanced,

        tradeoffs: {
            budgetButNotSlowest: {
                extraCostComparedWithCheapest:
                    round2(extraCost),

                timeSavedComparedWithSlowest:
                    round2(timeSaved)
            }
        },

        explanations: {
            bestOverall:
                `${bestOverall.provider} ${bestOverall.category} is the Best Overall option because it has the highest KaroScore of ${bestOverall.karoScore}/100.`,

            bestBudget:
                `${bestBudget.provider} ${bestBudget.category} is the Best Budget option because it has the lowest estimated fare of ₹${bestBudget.fare.toFixed(2)}.`,

            fastest:
                `${fastest.provider} ${fastest.category} is the Fastest option because its estimated ETA is ${fastest.eta} minutes.`,

            budgetButNotSlowest:
                budgetButNotSlowestExplanation,

            balanced:
                balancedExplanation
        }
    };
}

// =========================================================
// Preference-aware recommendation
// =========================================================

function getPreferenceRecommendation(
    smartRecommendations,
    preference
) {
    if (!preference) {
        return smartRecommendations.balanced;
    }

    const normalizedPreference =
        preference
            .toString()
            .trim()
            .toLowerCase();

    if (
        normalizedPreference === 'budget' ||
        normalizedPreference === 'cheap' ||
        normalizedPreference === 'price'
    ) {
        return smartRecommendations.bestBudget;
    }

    if (
        normalizedPreference === 'speed' ||
        normalizedPreference === 'fast' ||
        normalizedPreference === 'time'
    ) {
        return smartRecommendations.fastest;
    }

    if (
        normalizedPreference ===
            'budget_not_slowest' ||
        normalizedPreference ===
            'budget-but-not-slowest' ||
        normalizedPreference ===
            'cheap_but_fast'
    ) {
        return smartRecommendations
            .budgetButNotSlowest;
    }

    if (
        normalizedPreference === 'overall' ||
        normalizedPreference === 'best'
    ) {
        return smartRecommendations.bestOverall;
    }

    return smartRecommendations.balanced;
}

// =========================================================
// API
// =========================================================

app.get('/', (req, res) => {
    res.send('KaroCab API is Working');
});

// =========================================================
// ML FARE PREDICTION API
// =========================================================

app.post('/predict-fare', (req, res) => {
    const {
        distance,
        hour,
        weekend,
        demand,
        previousFare
    } = req.body;

    if (
        distance === undefined ||
        hour === undefined ||
        weekend === undefined ||
        !demand ||
        previousFare === undefined
    ) {
        return res.status(400).json({
            error:
                'Please provide distance, hour, weekend, demand and previousFare.'
        });
    }

    if (
        typeof distance !== 'number' ||
        typeof hour !== 'number' ||
        typeof previousFare !== 'number'
    ) {
        return res.status(400).json({
            error:
                'distance, hour and previousFare must be numbers.'
        });
    }

    if (distance <= 0) {
        return res.status(400).json({
            error:
                'Distance must be greater than 0.'
        });
    }

    if (hour < 0 || hour > 23) {
        return res.status(400).json({
            error:
                'Hour must be between 0 and 23.'
        });
    }

    if (previousFare <= 0) {
        return res.status(400).json({
            error:
                'previousFare must be greater than 0.'
        });
    }

    const prediction =
        getFarePrediction({
            distance,
            hour,
            weekend:
                weekend ? 1 : 0,
            demand,
            previousFare
        });

    return res.json({
        success: true,

        prediction,

        note:
            'Prediction is model-based and trained on simulated historical data. It is not a live provider fare.'
    });
});

// =========================================================
// ESTIMATE API
// =========================================================

app.post('/estimate', (req, res) => {
    const {
        distance,
        timeTaken,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData,

        // Optional preference.
        preference,

        // Optional ML inputs.
        hour,
        weekend,
        previousFare
    } = req.body;

    // ---------------------------------------------------------
    // Validation
    // ---------------------------------------------------------

    if (
        distance === undefined ||
        timeTaken === undefined ||
        !traffic ||
        !demand ||
        tolls === undefined ||
        !timeOfDay ||
        !route ||
        !historicData
    ) {
        return res.status(400).json({
            error:
                'Please provide all required parameters.'
        });
    }

    if (
        typeof distance !== 'number' ||
        typeof timeTaken !== 'number'
    ) {
        return res.status(400).json({
            error:
                'Distance and timeTaken must be numbers.'
        });
    }

    if (distance <= 0) {
        return res.status(400).json({
            error:
                'Distance must be greater than 0.'
        });
    }

    if (timeTaken <= 0) {
        return res.status(400).json({
            error:
                'timeTaken must be greater than 0.'
        });
    }

    // ---------------------------------------------------------
    // Calculate fares
    // ---------------------------------------------------------

    const uberCabFare =
        calculateFare(
            pricingModels.uberCab.baseFare,
            pricingModels.uberCab.costPerKm,
            distance,
            pricingModels.uberCab.costPerMinute,
            timeTaken,
            pricingModels.uberCab.surgeMultiplier,
            traffic,
            demand,
            tolls,
            timeOfDay,
            route,
            historicData
        );

    const uberAutoFare =
        calculateFare(
            pricingModels.uberAuto.baseFare,
            pricingModels.uberAuto.costPerKm,
            distance,
            pricingModels.uberAuto.costPerMinute,
            timeTaken,
            pricingModels.uberAuto.surgeMultiplier,
            traffic,
            demand,
            tolls,
            timeOfDay,
            route,
            historicData
        );

    const olaCabFare =
        calculateFare(
            pricingModels.olaCab.baseFare,
            pricingModels.olaCab.costPerKm,
            distance,
            pricingModels.olaCab.costPerMinute,
            timeTaken,
            pricingModels.olaCab.surgeMultiplier,
            traffic,
            demand,
            tolls,
            timeOfDay,
            route,
            historicData
        );

    const olaAutoFare =
        calculateFare(
            pricingModels.olaAuto.baseFare,
            pricingModels.olaAuto.costPerKm,
            distance,
            pricingModels.olaAuto.costPerMinute,
            timeTaken,
            pricingModels.olaAuto.surgeMultiplier,
            traffic,
            demand,
            tolls,
            timeOfDay,
            route,
            historicData
        );

    // ---------------------------------------------------------
    // Build ride list
    // ---------------------------------------------------------

    const rides = [
        {
            id: 'uberCab',

            provider:
                pricingModels.uberCab.provider,

            category:
                pricingModels.uberCab.category,

            fare: uberCabFare,

            // Demo ETA values only.
            // These are not live provider ETAs.
            eta: 5,

            duration:
                Number(timeTaken),

            comfort:
                pricingModels.uberCab.comfort,

            reliability:
                pricingModels.uberCab.reliability,

            safety:
                pricingModels.uberCab.safety
        },

        {
            id: 'uberAuto',

            provider:
                pricingModels.uberAuto.provider,

            category:
                pricingModels.uberAuto.category,

            fare: uberAutoFare,

            eta: 6,

            duration:
                Number(timeTaken),

            comfort:
                pricingModels.uberAuto.comfort,

            reliability:
                pricingModels.uberAuto.reliability,

            safety:
                pricingModels.uberAuto.safety
        },

        {
            id: 'olaCab',

            provider:
                pricingModels.olaCab.provider,

            category:
                pricingModels.olaCab.category,

            fare: olaCabFare,

            eta: 7,

            duration:
                Number(timeTaken),

            comfort:
                pricingModels.olaCab.comfort,

            reliability:
                pricingModels.olaCab.reliability,

            safety:
                pricingModels.olaCab.safety
        },

        {
            id: 'olaAuto',

            provider:
                pricingModels.olaAuto.provider,

            category:
                pricingModels.olaAuto.category,

            fare: olaAutoFare,

            eta: 8,

            duration:
                Number(timeTaken),

            comfort:
                pricingModels.olaAuto.comfort,

            reliability:
                pricingModels.olaAuto.reliability,

            safety:
                pricingModels.olaAuto.safety
        }
    ];

    // ---------------------------------------------------------
    // Calculate KaroScore
    // ---------------------------------------------------------

    const scoredRides =
        calculateKaroScore(rides);

    // ---------------------------------------------------------
    // Add explanations
    // ---------------------------------------------------------

    const explainedRides =
        scoredRides.map((ride) => ({
            ...ride,

            explanation:
                generateScoreExplanation(
                    ride
                )
        }));

    // ---------------------------------------------------------
    // Smart Recommendations
    // ---------------------------------------------------------

    const smartRecommendations =
        calculateSmartRecommendations(
            explainedRides
        );

    // ---------------------------------------------------------
    // Preference recommendation
    // ---------------------------------------------------------

    const preferenceRide =
        getPreferenceRecommendation(
            smartRecommendations,
            preference
        );

    // ---------------------------------------------------------
    // ML Fare Prediction
    // ---------------------------------------------------------

    const currentHour =
        typeof hour === 'number'
            ? hour
            : new Date().getHours();

    const currentWeekend =
        typeof weekend === 'boolean'
            ? weekend
            : false;

    const cheapestFare =
        smartRecommendations
            .bestBudget
            .fare;

    const mlPreviousFare =
        typeof previousFare === 'number'
            ? previousFare
            : cheapestFare;

    const farePrediction =
        getFarePrediction({
            distance,
            hour: currentHour,
            weekend:
                currentWeekend ? 1 : 0,
            demand,
            previousFare:
                mlPreviousFare
        });

    // ---------------------------------------------------------
    // Response
    // ---------------------------------------------------------

    return res.json({
        distance:
            round2(distance),

        duration:
            Number(timeTaken),

        // -----------------------------------------------------
        // Ride data
        // -----------------------------------------------------

        rides:
            explainedRides.map(
                (ride) => ({
                    id: ride.id,

                    provider:
                        ride.provider,

                    category:
                        ride.category,

                    fare:
                        round2(ride.fare),

                    eta:
                        ride.eta,

                    duration:
                        ride.duration,

                    karoScore:
                        ride.karoScore,

                    scores:
                        ride.scores,

                    explanation:
                        ride.explanation
                })
            ),

        // -----------------------------------------------------
        // Existing recommendations
        // -----------------------------------------------------

        recommendations: {
            bestOverall:
                smartRecommendations
                    .bestOverall.id,

            bestBudget:
                smartRecommendations
                    .bestBudget.id,

            fastest:
                smartRecommendations
                    .fastest.id,

            // -------------------------------------------------
            // Intelligent recommendations
            // -------------------------------------------------

            budgetButNotSlowest:
                smartRecommendations
                    .budgetButNotSlowest.id,

            balanced:
                smartRecommendations
                    .balanced.id,

            preference:
                preferenceRide
                    ? preferenceRide.id
                    : null,

            explanations:
                smartRecommendations
                    .explanations,

            tradeoffs:
                smartRecommendations
                    .tradeoffs
        },

        // -----------------------------------------------------
        // FARE PREDICTION
        // -----------------------------------------------------

        farePrediction,

        // -----------------------------------------------------
        // Metadata
        // -----------------------------------------------------

        recommendationModel: {
            balancedWeights: {
                price: 40,
                speed: 30,
                karoScore: 30
            },

            note:
                'Recommendations are calculated from KaroCab estimated/simulated comparison data.'
        },

        predictionModel: {
            algorithm:
                'Linear Regression',

            features: [
                'distance',
                'hour',
                'weekend',
                'demand',
                'previousFare'
            ],

            target:
                'historical fare',

            trainingData:
                'simulated historical data',

            metrics:
                fareModelMetrics,

            note:
                'Fare prediction is model-based and should not be presented as a live provider quote.'
        }
    });
});

// =========================================================
// Start server
// =========================================================

const PORT =
    process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(
        `KaroCab API running on port ${PORT}`
    );

    console.log(
        'Fare Prediction ML model: Linear Regression'
    );

    console.log(
        `ML metrics: MAE=${fareModelMetrics.mae}, RMSE=${fareModelMetrics.rmse}, R2=${fareModelMetrics.r2}`
    );
});