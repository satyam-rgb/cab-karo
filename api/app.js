import express, { json } from 'express';

const app = express();

app.use(json());

// =========================================================
// KaroScore helpers
// =========================================================

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

// =========================================================
// Utility helpers
// =========================================================

function round2(value) {
    return Number(Number(value).toFixed(2));
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
    const durations = rides.map((ride) => ride.duration);

    const minFare = Math.min(...fares);
    const maxFare = Math.max(...fares);

    const minEta = Math.min(...etas);
    const maxEta = Math.max(...etas);

    const minDuration = Math.min(...durations);
    const maxDuration = Math.max(...durations);

    return rides.map((ride) => {
        // Lower is better
        const priceScore = lowerIsBetterScore(
            ride.fare,
            minFare,
            maxFare
        );

        const etaScore = lowerIsBetterScore(
            ride.eta,
            minEta,
            maxEta
        );

        const durationScore = lowerIsBetterScore(
            ride.duration,
            minDuration,
            maxDuration
        );

        // Higher is better
        const comfortScore = ride.comfort;
        const reliabilityScore = ride.reliability;
        const safetyScore = ride.safety;

        // KaroScore weights
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
                reliability: round2(reliabilityScore),
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

    const contributions = factors.map((factor) => ({
        name: factor.name,
        score: factor.score,
        weight: factor.weight,
        contribution:
            factor.score * (factor.weight / 100)
    }));

    contributions.sort(
        (a, b) => b.contribution - a.contribution
    );

    const strongestFactor = contributions[0];

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
                    round2(scores.price * 0.35)
            },

            eta: {
                score: scores.eta,
                weight: 20,
                contribution:
                    round2(scores.eta * 0.20)
            },

            duration: {
                score: scores.duration,
                weight: 15,
                contribution:
                    round2(scores.duration * 0.15)
            },

            comfort: {
                score: scores.comfort,
                weight: 10,
                contribution:
                    round2(scores.comfort * 0.10)
            },

            reliability: {
                score: scores.reliability,
                weight: 10,
                contribution:
                    round2(scores.reliability * 0.10)
            },

            safety: {
                score: scores.safety,
                weight: 10,
                contribution:
                    round2(scores.safety * 0.10)
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

    // ---------------------------------------------------------
    // 1. Best Overall
    // Highest KaroScore
    // ---------------------------------------------------------

    const bestOverall =
        [...rides].sort(sortByKaroScore)[0];

    // ---------------------------------------------------------
    // 2. Best Budget
    // Lowest fare
    // ---------------------------------------------------------

    const bestBudget =
        [...rides].sort(sortByFare)[0];

    // ---------------------------------------------------------
    // 3. Fastest
    // Lowest ETA
    // ---------------------------------------------------------

    const fastest =
        [...rides].sort(sortByEta)[0];

    // ---------------------------------------------------------
    // 4. Budget + Not Slowest
    //
    // First identify slowest ride.
    // Remove slowest.
    // Then choose cheapest remaining ride.
    // ---------------------------------------------------------

    const slowest =
        [...rides].sort(
            (a, b) => b.eta - a.eta
        )[0];

    let budgetButNotSlowest;

    if (rides.length > 1) {
        const alternatives =
            rides.filter(
                (ride) => ride.id !== slowest.id
            );

        budgetButNotSlowest =
            [...alternatives].sort(sortByFare)[0];
    } else {
        budgetButNotSlowest = rides[0];
    }

    // ---------------------------------------------------------
    // 5. Balanced Choice
    //
    // Uses:
    // Price = 40%
    // Speed = 30%
    // KaroScore = 30%
    //
    // This is separate from the base KaroScore so that
    // recommendation logic can explain its own trade-off.
    // ---------------------------------------------------------

    const fares = rides.map(
        (ride) => ride.fare
    );

    const etas = rides.map(
        (ride) => ride.eta
    );

    const minFare = Math.min(...fares);
    const maxFare = Math.max(...fares);

    const minEta = Math.min(...etas);
    const maxEta = Math.max(...etas);

    const balancedRides = rides.map((ride) => {
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
                priceScore: round2(priceScore),
                speedScore: round2(speedScore),
                balancedScore: round2(
                    balancedScore
                )
            }
        };
    });

    const balanced =
        [...balancedRides].sort(
            (a, b) =>
                b.recommendationScores.balancedScore -
                a.recommendationScores.balancedScore
        )[0];

    // ---------------------------------------------------------
    // Trade-off calculations
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // Explanations
    // ---------------------------------------------------------

    const budgetButNotSlowestExplanation =
        budgetButNotSlowest.id === bestBudget.id
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
        normalizedPreference === 'budget_not_slowest' ||
        normalizedPreference === 'budget-but-not-slowest' ||
        normalizedPreference === 'cheap_but_fast'
    ) {
        return smartRecommendations.budgetButNotSlowest;
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
        // Existing app does not need to send this.
        preference
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

    const uberCabFare = calculateFare(
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

    const uberAutoFare = calculateFare(
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

    const olaCabFare = calculateFare(
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

    const olaAutoFare = calculateFare(
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

            duration: Number(timeTaken),

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

            duration: Number(timeTaken),

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

            duration: Number(timeTaken),

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

            duration: Number(timeTaken),

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
        scoredRides.map((ride) => {
            return {
                ...ride,

                explanation:
                    generateScoreExplanation(
                        ride
                    )
            };
        });

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
    // Response
    // ---------------------------------------------------------

    return res.json({
        distance: round2(distance),

        duration: Number(timeTaken),

        // -----------------------------------------------------
        // Ride data
        // -----------------------------------------------------

        rides: explainedRides.map((ride) => ({
            id: ride.id,

            provider: ride.provider,

            category: ride.category,

            fare: round2(ride.fare),

            eta: ride.eta,

            duration: ride.duration,

            karoScore: ride.karoScore,

            scores: ride.scores,

            explanation:
                ride.explanation
        })),

        // -----------------------------------------------------
        // Existing recommendations
        //
        // Kept exactly compatible with current Flutter UI.
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
            // New intelligent recommendations
            // -------------------------------------------------

            budgetButNotSlowest:
                smartRecommendations
                    .budgetButNotSlowest.id,

            balanced:
                smartRecommendations
                    .balanced.id,

            // -------------------------------------------------
            // Preference-based recommendation
            // -------------------------------------------------

            preference:
                preferenceRide
                    ? preferenceRide.id
                    : null,

            // -------------------------------------------------
            // Explanations
            // -------------------------------------------------

            explanations:
                smartRecommendations.explanations,

            // -------------------------------------------------
            // Trade-off information
            // -------------------------------------------------

            tradeoffs:
                smartRecommendations.tradeoffs
        },

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
});