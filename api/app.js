import express, { json } from 'express';

const app = express();
app.use(json());

// ---------------------------------------------------------
// KaroScore helpers
// ---------------------------------------------------------

// Lower value is better.
// Converts a value into a 0-100 score relative to the best/worst
// values present in the current ride comparison.
function lowerIsBetterScore(value, min, max) {
    if (max === min) return 100;

    return ((max - value) / (max - min)) * 100;
}

// Higher value is better.
function higherIsBetterScore(value, min, max) {
    if (max === min) return 100;

    return ((value - min) / (max - min)) * 100;
}

// ---------------------------------------------------------
// Fare calculation
// ---------------------------------------------------------

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
        (baseFare +
            costPerKm * distance +
            costPerMinute * timeTaken) *
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

// ---------------------------------------------------------
// Ride models
// ---------------------------------------------------------

const pricingModels = {
    uberCab: {
        provider: 'Uber',
        category: 'Cab',
        baseFare: 50,
        costPerKm: 12,
        costPerMinute: 1.2,
        surgeMultiplier: 1.5,

        // Initial demo values.
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

// ---------------------------------------------------------
// KaroScore calculation
// ---------------------------------------------------------

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
                price: Number(priceScore.toFixed(2)),
                eta: Number(etaScore.toFixed(2)),
                duration: Number(durationScore.toFixed(2)),
                comfort: Number(comfortScore.toFixed(2)),
                reliability: Number(reliabilityScore.toFixed(2)),
                safety: Number(safetyScore.toFixed(2))
            },
            karoScore: Number(karoScore.toFixed(2))
        };
    });
}

// ---------------------------------------------------------
// API
// ---------------------------------------------------------

app.get('/', (req, res) => {
    res.send('KaroCab API is Working');
});

app.post('/estimate', (req, res) => {
    const {
        distance,
        timeTaken,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData
    } = req.body;

    // Only reject missing values.
    // 0 tolls is a valid value.
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
            error: 'Please provide all required parameters.'
        });
    }

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

    // -----------------------------------------------------
    // Build ride list
    // -----------------------------------------------------

    const rides = [
        {
            id: 'uberCab',
            provider: pricingModels.uberCab.provider,
            category: pricingModels.uberCab.category,
            fare: uberCabFare,
            eta: 5,
            duration: Number(timeTaken),
            comfort: pricingModels.uberCab.comfort,
            reliability: pricingModels.uberCab.reliability,
            safety: pricingModels.uberCab.safety
        },
        {
            id: 'uberAuto',
            provider: pricingModels.uberAuto.provider,
            category: pricingModels.uberAuto.category,
            fare: uberAutoFare,
            eta: 6,
            duration: Number(timeTaken),
            comfort: pricingModels.uberAuto.comfort,
            reliability: pricingModels.uberAuto.reliability,
            safety: pricingModels.uberAuto.safety
        },
        {
            id: 'olaCab',
            provider: pricingModels.olaCab.provider,
            category: pricingModels.olaCab.category,
            fare: olaCabFare,
            eta: 7,
            duration: Number(timeTaken),
            comfort: pricingModels.olaCab.comfort,
            reliability: pricingModels.olaCab.reliability,
            safety: pricingModels.olaCab.safety
        },
        {
            id: 'olaAuto',
            provider: pricingModels.olaAuto.provider,
            category: pricingModels.olaAuto.category,
            fare: olaAutoFare,
            eta: 8,
            duration: Number(timeTaken),
            comfort: pricingModels.olaAuto.comfort,
            reliability: pricingModels.olaAuto.reliability,
            safety: pricingModels.olaAuto.safety
        }
    ];

    // Calculate KaroScore
    const scoredRides = calculateKaroScore(rides);

    // Best Overall = highest KaroScore
    const bestOverall = [...scoredRides].sort(
        (a, b) => b.karoScore - a.karoScore
    )[0];

    // Best Budget = lowest fare
    const bestBudget = [...scoredRides].sort(
        (a, b) => a.fare - b.fare
    )[0];

    // Fastest = lowest ETA
    const fastest = [...scoredRides].sort(
        (a, b) => a.eta - b.eta
    )[0];

    return res.json({
        distance: Number(distance),
        duration: Number(timeTaken),

        rides: scoredRides.map((ride) => ({
            id: ride.id,
            provider: ride.provider,
            category: ride.category,
            fare: Number(ride.fare.toFixed(2)),
            eta: ride.eta,
            duration: ride.duration,
            karoScore: ride.karoScore,
            scores: ride.scores
        })),

        recommendations: {
            bestOverall: bestOverall.id,
            bestBudget: bestBudget.id,
            fastest: fastest.id
        }
    });
});

// ---------------------------------------------------------
// Start server
// ---------------------------------------------------------

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`KaroCab API running on port ${PORT}`);
});