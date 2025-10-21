/*******************************************************************
TA Session 4 - Introduction to Stata
Author: Lucia Sauer
Contact: lucia.sauer@bse.eu
Date: 2025-10-15
Dataset: bwght (Wooldridge)

Contents: 
	1. F test
*******************************************************************/



*******************************************************************
* 1. Load Dataset
*******************************************************************

* Load Wooldridge dataset
bcuse gpa1, clear // import the dataset



*******************************************************************
* 2. Regression Analysis
*******************************************************************

* Model:
* colGPA_i = β1 + β2*hsGPA_i + β3*job19_i + β4*job20_i + β5*skipped_i + β6*bgfriend_i + β7*alcohol_i + ε_i
reg colGPA hsGPA job19 job20 skipped bgfriend alcohol


*******************************************************************
* 3.1 Hypothesis Testing: significance of all the regressors
*******************************************************************

// Compute the Restricted Sum of Squared Errors (RSSE)
// Restricted model: only the mean of colGPA
summarize colGPA
scalar colgpa_mean = r(mean)
generate double resid_R = colGPA - colgpa_mean
generate double resid_R_sq = resid_R^2
summarize resid_R_sq
scalar RSSE = r(sum)

// Extract SSE from the unrestricted model
scalar SSE = e(rss)

// Compute the manual F-statistic
scalar F_manual = ((RSSE - SSE) / 6) / (SSE / (e(N) - 7))
display "Manual F = " F_manual

// Compare with Stata's reported F
display "Stata F = " e(F)

// Compute critical value at 5% significance
scalar F_critical = invF(6, e(N) - 7, 0.95)
display "Critical value (5%): " F_critical

// Compute p-value
scalar p_value = 1 - F(F_manual, 6, e(N) - 7)
display "p-value = " p_value



*******************************************************************
* 3.2 Hypothesis Testing: significance of motheduc and fatheduc
*******************************************************************
reg colGPA hsGPA job19 job20 skipped bgfriend alcohol

* Null and alternative hypotheses:
*   H0: β3 = β4 = 0
*   H1: not H0


* Perform the F test:
test job19 job20

*If we want manually to contruct the F statistic

*1. Run restricted model and get sse
reg colGPA hsGPA skipped bgfriend alcohol
scalar sse_r = e(rss)

*2. Run unrestricted model and get sse
reg colGPA hsGPA job19 job20 skipped bgfriend alcohol
scalar sse = e(rss)
scalar df = 141 - 7

*3. Compute statistic
scalar F = ((sse_r - sse)/2) / (sse/df)
display F

*******************************************************************
* 3.3 Decision Rule
*******************************************************************

* If F > F_crit, reject H0.
display invFtail(2, 141-7, 0.05)

local p_value Ftail(2, 141-7, F)
display "P-value: "`p_value'
