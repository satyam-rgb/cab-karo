import express, { json } from 'express';

const app = express();

app.use(json());

// =========================================================
// BASIC HELPERS
// =========================================================

function round2(value) {
    return Number(Number(value).toFixed(2));
}

function lowerIsBetterScore(value, min, max) {
    if (max === min) return 100;

    return ((max - value) / (max - min)) * 100;
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
// FARE PREDICTION - LINEAR REGRESSION BASELINE
// =========================================================

// Simulated historical training data for the final-year project.
// It is not live provider data.

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

// =========================================================
// MATRIX HELPERS
// =========================================================

function matrixTranspose(matrix) {
    if (!matrix.length) return [];

    return matrix[0].map((_, column) =>
        matrix.map((row) => row[column])
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
        ...Array.from(
            { length: n },
            (_, j) => (i === j ? 1 : 0)
        )
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
                augmented[row][j] -=
                    factor * augmented[column][j];
            }
        }
    }

    return augmented.map((row) => row.slice(n));
}

function trainLinearRegression(data) {
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

const fareModelCoefficients =
    trainLinearRegression(fareTrainingData);

function normalizeDemand(demand) {
    const value =
        demand?.toString().trim().toLowerCase();

    if (value === 'high') return 2;
    if (value === 'medium') return 1;

    return 0;
}

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
        normalizeDemand(demand),
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

    const mae =
        errors
            .map(Math.abs)
            .reduce((sum, value) => sum + value, 0) /
        actual.length;

    const mse =
        errors
            .map((value) => value * value)
            .reduce((sum, value) => sum + value, 0) /
        actual.length;

    const rmse = Math.sqrt(mse);

    const meanActual =
        actual.reduce((sum, value) => sum + value, 0) /
        actual.length;

    const totalSumSquares =
        actual.reduce(
            (sum, value) =>
                sum + Math.pow(value - meanActual, 2),
            0
        );

    const residualSumSquares =
        errors.reduce(
            (sum, value) => sum + value * value,
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
    calculateRegressionMetrics(fareTrainingData);

function getFarePrediction({
    distance,
    hour,
    weekend,
    demand,
    previousFare
}) {
    const predictedFare =
        predictFareWithModel({
            distance,
            hour,
            weekend,
            demand,
            previousFare
        });

    const currentFare = Number(previousFare);
    const change = predictedFare - currentFare;

    const changePercent =
        currentFare > 0
            ? (change / currentFare) * 100
            : 0;

    let trend = 'stable';

    if (changePercent > 5) {
        trend = 'up';
    } else if (changePercent < -5) {
        trend = 'down';
    }

    let recommendation = 'Consider Waiting';

    if (trend === 'up') {
        recommendation = 'Book Now';
    } else if (trend === 'stable') {
        recommendation =
            'Either option is reasonable';
    }

    return {
        predictedFare: round2(predictedFare),
        currentFare: round2(currentFare),
        expectedChange: round2(change),
        expectedChangePercent: round2(changePercent),
        trend,
        recommendation,
        model: 'Linear Regression',
        dataType:
            'Simulated historical training data',
        metrics: fareModelMetrics
    };
}

// =========================================================
// FARE CALCULATION
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

    const timeOfDayMultiplier =
        timeOfDay === 'night' ? 1.3 : 1;

    let fare =
        (
            baseFare +
            costPerKm * distance +
            costPerMinute * timeTaken
        ) * surgeMultiplier;

    fare *= trafficMultiplier;
    fare *= demandMultiplier;
    fare *= timeOfDayMultiplier;

    fare += Number(tolls);

    if (historicData === 'high_demand_area') {
        fare *= 1.2;
    }

    return fare;
}

// =========================================================
// RIDE MODELS
// =========================================================

const pricingModels = {
    uberCab: {
        provider: 'Uber',
        category: 'Cab',
        baseFare: 50,
        costPerKm: 12,
        costPerMinute: 1.2,
        surgeMultiplier: 1.5,
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
// KAROSCORE
// =========================================================

function calculateKaroScore(rides, goal = 'budget') {
    if (!rides.length) {
        return [];
    }

    const fares = rides.map((ride) => Number(ride.fare));
    const etas = rides.map((ride) => Number(ride.eta));
    const durations = rides.map((ride) => Number(ride.duration));

    const minFare = Math.min(...fares);
    const maxFare = Math.max(...fares);

    const minEta = Math.min(...etas);
    const maxEta = Math.max(...etas);

    const minDuration = Math.min(...durations);
    const maxDuration = Math.max(...durations);

    // Budget mode:
    // Price 40%
    // ETA 10%
    // Duration 10%
    // Safety 15%
    // Comfort 10%
    // Reliability 15%

    // Hurry mode:
    // Price 10%
    // ETA 30%
    // Duration 25%
    // Safety 15%
    // Comfort 10%
    // Reliability 10%

    const weights =
        goal === 'hurry'
            ? {
                  price: 0.10,
                  eta: 0.30,
                  duration: 0.25,
                  safety: 0.15,
                  comfort: 0.10,
                  reliability: 0.10
              }
            : {
                  price: 0.40,
                  eta: 0.10,
                  duration: 0.10,
                  safety: 0.15,
                  comfort: 0.10,
                  reliability: 0.15
              };

    return rides.map((ride) => {
        const priceScore =
            lowerIsBetterScore(
                Number(ride.fare),
                minFare,
                maxFare
            );

        const etaScore =
            lowerIsBetterScore(
                Number(ride.eta),
                minEta,
                maxEta
            );

        const durationScore =
            lowerIsBetterScore(
                Number(ride.duration),
                minDuration,
                maxDuration
            );

        const safetyScore = Math.max(
            0,
            Math.min(100, Number(ride.safety) || 0)
        );

        const comfortScore = Math.max(
            0,
            Math.min(100, Number(ride.comfort) || 0)
        );

        const reliabilityScore = Math.max(
            0,
            Math.min(100, Number(ride.reliability) || 0)
        );

        const karoScore =
            priceScore * weights.price +
            etaScore * weights.eta +
            durationScore * weights.duration +
            safetyScore * weights.safety +
            comfortScore * weights.comfort +
            reliabilityScore * weights.reliability;

        return {
            ...ride,

            scores: {
                price: round2(priceScore),
                eta: round2(etaScore),
                duration: round2(durationScore),
                safety: round2(safetyScore),
                comfort: round2(comfortScore),
                reliability: round2(reliabilityScore)
            },

            scoreWeights: {
                price: weights.price * 100,
                eta: weights.eta * 100,
                duration: weights.duration * 100,
                safety: weights.safety * 100,
                comfort: weights.comfort * 100,
                reliability: weights.reliability * 100
            },

            karoScore: round2(karoScore)
        };
    });
}

// =========================================================
// KAROSCORE EXPLANATION
// =========================================================

function generateScoreExplanation(ride) {
    const scores = ride.scores;

    const weights = ride.scoreWeights || {
        price: 40,
        eta: 10,
        duration: 10,
        safety: 15,
        comfort: 10,
        reliability: 15
    };

    const factors = [
        {
            name: 'Price',
            score: scores.price,
            weight: weights.price
        },
        {
            name: 'ETA',
            score: scores.eta,
            weight: weights.eta
        },
        {
            name: 'Duration',
            score: scores.duration,
            weight: weights.duration
        },
        {
            name: 'Safety',
            score: scores.safety,
            weight: weights.safety
        },
        {
            name: 'Comfort',
            score: scores.comfort,
            weight: weights.comfort
        },
        {
            name: 'Reliability',
            score: scores.reliability,
            weight: weights.reliability
        }
    ];

    const contributions = factors
        .map((factor) => ({
            name: factor.name,
            score: factor.score,
            weight: factor.weight,
            contribution:
                factor.score *
                factor.weight /
                100
        }))
        .sort(
            (a, b) =>
                b.contribution -
                a.contribution
        );

    const strongestFactor =
        contributions[0];

    let summary =
        'Lower overall score compared with the other available options.';

    if (ride.karoScore >= 75) {
        summary =
            'Strong overall score based on the current comparison.';
    } else if (ride.karoScore >= 60) {
        summary =
            'Balanced option with a moderate overall score.';
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
                weight: weights.price,
                contribution:
                    round2(
                        scores.price *
                        weights.price /
                        100
                    )
            },

            eta: {
                score: scores.eta,
                weight: weights.eta,
                contribution:
                    round2(
                        scores.eta *
                        weights.eta /
                        100
                    )
            },

            duration: {
                score: scores.duration,
                weight: weights.duration,
                contribution:
                    round2(
                        scores.duration *
                        weights.duration /
                        100
                    )
            },

            safety: {
                score: scores.safety,
                weight: weights.safety,
                contribution:
                    round2(
                        scores.safety *
                        weights.safety /
                        100
                    )
            },

            comfort: {
                score: scores.comfort,
                weight: weights.comfort,
                contribution:
                    round2(
                        scores.comfort *
                        weights.comfort /
                        100
                    )
            },

            reliability: {
                score: scores.reliability,
                weight: weights.reliability,
                contribution:
                    round2(
                        scores.reliability *
                        weights.reliability /
                        100
                    )
            }
        }
    };
}
// =========================================================
// CALCULATE SMART RECOMMENDATIONS
// =========================================================

function calculateSmartRecommendations(rides) {

    if (!rides.length) {

        return {

            bestOverall: null,

            bestBudget: null,

            fastest: null,

            budgetButNotSlowest: null,

            balanced: null

        };

    }



    const bestOverall =

        [...rides].sort(sortByKaroScore)[0];



    const bestBudget =

        [...rides].sort(sortByFare)[0];



    const fastest =

        [...rides].sort(sortByEta)[0];



    const slowest =

        [...rides].sort(

            (a, b) => b.eta - a.eta

        )[0];



    const alternatives =

        rides.filter(

            (ride) => ride.id !== slowest.id

        );



    const budgetButNotSlowest =

        alternatives.length

            ? [...alternatives].sort(sortByFare)[0]

            : rides[0];



    const fares =

        rides.map((ride) => ride.fare);



    const etas =

        rides.map((ride) => ride.eta);



    const minFare = Math.min(...fares);

    const maxFare = Math.max(...fares);

    const minEta = Math.min(...etas);

    const maxEta = Math.max(...etas);



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

                        round2(balancedScore)

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



    const extraCost =

        budgetButNotSlowest.fare -

        bestBudget.fare;



    const timeSaved =

        slowest.eta -

        budgetButNotSlowest.eta;



    const budgetExplanation =

        budgetButNotSlowest.id === bestBudget.id

            ? `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} is both the cheapest option and not the slowest ride.`

            : `${budgetButNotSlowest.provider} ${budgetButNotSlowest.category} is recommended for users who want to save money without choosing the slowest ride. The slowest option is ${slowest.provider} ${slowest.category} at ${slowest.eta} minutes.`;



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

                budgetExplanation,



            balanced:

                `${balanced.provider} ${balanced.category} provides the strongest balance of estimated price, ETA and current KaroScore under the balanced recommendation model.`

        }

    };

}



function getPreferenceRecommendation(

    recommendations,

    preference

) {

    if (!preference) {

        return recommendations.balanced;

    }



    const value =

        preference

            .toString()

            .trim()

            .toLowerCase();



    if (

        value === 'budget' ||

        value === 'cheap' ||

        value === 'price'

    ) {

        return recommendations.bestBudget;

    }



    if (

        value === 'speed' ||

        value === 'fast' ||

        value === 'time'

    ) {

        return recommendations.fastest;

    }



    if (

        value === 'budget_not_slowest' ||

        value === 'budget-but-not-slowest' ||

        value === 'cheap_but_fast'

    ) {

        return recommendations.budgetButNotSlowest;

    }



    if (

        value === 'overall' ||

        value === 'best'

    ) {

        return recommendations.bestOverall;

    }



    return recommendations.balanced;

}



// =========================================================
// BASIC API
// =========================================================

app.get('/', (req, res) => {

    res.send('KaroCab API is Working');

});



// =========================================================
// DIRECT FARE PREDICTION API
// =========================================================

app.post('/predict-fare', (req, res) => {

    const {

        distance,

        hour,

        weekend,

        demand,

        previousFare

    } = req.body;



    const weekendValue =

        weekend === true || weekend === 1

            ? 1

            : 0;



    if (

        typeof distance !== 'number' ||

        typeof hour !== 'number' ||

        typeof previousFare !== 'number' ||

        ![true, false, 0, 1].includes(weekend) ||

        !demand

    ) {

        return res.status(400).json({

            error:

                'Please provide distance, hour, weekend, demand and previousFare.'

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

            weekend: weekendValue,

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

        preference,



        // Optional ML inputs.

        hour,

        weekend,

        previousFare

    } = req.body;



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



    const rides = [

        {

            id: 'uberCab',

            provider: 'Uber',

            category: 'Cab',

            fare: uberCabFare,

            eta: 5,

            duration: Number(timeTaken),

            comfort: pricingModels.uberCab.comfort,

            reliability: pricingModels.uberCab.reliability,

            safety: pricingModels.uberCab.safety

        },

        {

            id: 'uberAuto',

            provider: 'Uber',

            category: 'Auto',

            fare: uberAutoFare,

            eta: 6,

            duration: Number(timeTaken),

            comfort: pricingModels.uberAuto.comfort,

            reliability: pricingModels.uberAuto.reliability,

            safety: pricingModels.uberAuto.safety

        },

        {

            id: 'olaCab',

            provider: 'Ola',

            category: 'Cab',

            fare: olaCabFare,

            eta: 7,

            duration: Number(timeTaken),

            comfort: pricingModels.olaCab.comfort,

            reliability: pricingModels.olaCab.reliability,

            safety: pricingModels.olaCab.safety

        },

        {

            id: 'olaAuto',

            provider: 'Ola',

            category: 'Auto',

            fare: olaAutoFare,

            eta: 8,

            duration: Number(timeTaken),

            comfort: pricingModels.olaAuto.comfort,

            reliability: pricingModels.olaAuto.reliability,

            safety: pricingModels.olaAuto.safety

        }

    ];



    // IMPORTANT:
    // KaroScore now uses the documented Budget weights.
    const scoredRides =

        calculateKaroScore(rides, 'budget');



    const explainedRides =

        scoredRides.map((ride) => ({

            ...ride,

            explanation:

                generateScoreExplanation(ride)

        }));



    const smartRecommendations =

        calculateSmartRecommendations(

            explainedRides

        );



    const preferenceRide =

        getPreferenceRecommendation(

            smartRecommendations,

            preference

        );



    // Fare prediction defaults to the current
    // cheapest estimated ride when previousFare
    // is not supplied by the app.

    const predictionHour =

        typeof hour === 'number'

            ? hour

            : new Date().getHours();



    const predictionWeekend =

        weekend === true || weekend === 1

            ? 1

            : 0;



    const predictionPreviousFare =

        typeof previousFare === 'number' &&

        previousFare > 0

            ? previousFare

            : smartRecommendations.bestBudget.fare;



    const farePrediction =

        getFarePrediction({

            distance,

            hour: predictionHour,

            weekend: predictionWeekend,

            demand,

            previousFare:

                predictionPreviousFare

        });



    return res.json({

        distance: round2(distance),

        duration: Number(timeTaken),



        rides: explainedRides.map((ride) => ({

            id: ride.id,

            provider: ride.provider,

            category: ride.category,

            fare: round2(ride.fare),

            eta: ride.eta,

            duration: ride.duration,

            karoScore: ride.karoScore,

            scores: ride.scores,

            explanation: ride.explanation

        })),



        recommendations: {

            bestOverall:

                smartRecommendations.bestOverall.id,



            bestBudget:

                smartRecommendations.bestBudget.id,



            fastest:

                smartRecommendations.fastest.id,



            budgetButNotSlowest:

                smartRecommendations

                    .budgetButNotSlowest.id,



            balanced:

                smartRecommendations.balanced.id,



            preference:

                preferenceRide

                    ? preferenceRide.id

                    : null,



            explanations:

                smartRecommendations.explanations,



            tradeoffs:

                smartRecommendations.tradeoffs

        },



        // New ML feature.
        farePrediction,



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
// START SERVER
// =========================================================

const PORT =

    process.env.PORT || 3000;



app.listen(PORT, () => {

    console.log(

        `KaroCab API running on port ${PORT}`

    );

});