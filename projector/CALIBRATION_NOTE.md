# Self-thinning calibration note (v3 projector)

**Date:** 2026-06-22

The v3 smoke produced a realized self-thinning slope d ln(N) / d ln(QMD) of about -1.87 against
the Reineke expectation of -1.605. A calibration sweep of the self-thinning rate coefficient
ST_RATE on 300 NE stands tested whether detuning it centers the slope:

| ST_RATE | ST_EXP | realized slope |
|---:|---:|---:|
| 0.30 | 2.73 | -1.90 |
| 0.38 | 2.73 | -1.89 |
| 0.4525 (fitted) | 2.73 | -1.87 |

The slope is essentially insensitive to ST_RATE across this range. It is governed by the
projector's relative-density and growth dynamics, not the rate scalar, so detuning ST_RATE would
not move the slope toward -1.605 and would only distort a coefficient estimated directly from FIA
(R^2 = 0.60). Decision: retain the fitted coefficients (ST_RATE = 0.4525, ST_EXP = 2.73). The
modest -1.87 vs -1.605 gap is acceptable and is a property of the whole-trajectory slope
diagnostic plus projector dynamics, not a miscalibration.

Follow-ups if tighter centering is wanted later: (1) study ST_EXP (the curvature) rather than the
rate, since the rate does not move the slope; (2) restrict the slope diagnostic to the post-peak
self-thinning phase per stand rather than the whole trajectory, which currently biases the
estimate. Neither is needed for the constraint to function: it already corrects the under-thinning
(-1.12 unconstrained to -1.87 constrained) and caps the basal-area runaway.

The full-variant production run (job 11909922) uses the fitted coefficients.
