/* ===================================================================
              FOUNDATIONS OF ECONOMETRICS - DSDM 2025-26
                    TA #7 - Instrumental Variables
 -------------------------------------------------------------------
 TA:    Lucia Sauer
 Email: lucia.sauer@bse.eu
 ===================================================================
*/

* Clean up the workspace
clear all          // Clears all data from memory
cls                // Clears the command window
cap set more off   // Turns off --more-- prompt
set maxvar 32000   // Sets maximum number of variables (for larger datasets)

* ===================================================================
* 1. Returns on education
* ===================================================================

/*
Goal: Estimate returns to education correcting for endogeneity.
Data: Mroz (Wooldridge)
*/

use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz, clear

* ---------- First Stage ----------
regress educ fatheduc motheduc exper expersq if !missing(lwage)

* Predicted education
predict educhat

* ---------- Second Stage ----------
regress lwage educhat exper expersq

* ---------- Equivalent IV Estimation ----------
ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)


* ===================================================================
* 2. FEMALE LABOR FORCE PARTICIPATION (IV-PROBIT)
* ===================================================================

/*
Goal: Estimate the effect of household income on female labor supply.
Model:
   fem_work  = β0 + β1*fem_educ + β2*kids + β3*other_inc + u

Endogeneity concern:
- other_inc may be correlated with unobserved family traits.

Instrument:
- male_educ (assumed to affect income, not participation directly).

Controls:
- fem_educ (female education)
- kids (number of children)

*/

clear all
cls
cap set more off
set maxvar 32000

* ---------- Load dataset ----------
webuse laborsup, clear

* ---------- IV-Probit estimation ----------
ivprobit fem_work fem_educ kids (other_inc = male_educ)


* ===================================================================
* 3. MARGINAL EFFECTS AND VISUALIZATION
* ===================================================================

/*
Marginal effects show how the probability of working changes
as the number of kids increases, holding other factors constant.

The option at(kids=(1(1)4)) computes predicted probabilities
for 1, 2, 3, and 4 children.
*/

margins, at(kids=(1(1)4)) predict(pr)

* ---------- Plot Marginal Effects ----------
marginsplot, ///
    graphregion(fcolor(white)) ///
    title("Effect of Number of Kids on Probability of Female Work")


