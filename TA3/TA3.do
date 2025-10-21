/*******************************************************************
TA Session 3 - Introduction to Stata
Author: Lucia Sauer
Contact: lucia.sauer@bse.eu
Date: 2025-10-10
Dataset: bwght (Wooldridge)

Contents: 
	1. Regression Analysis
	2. Hypothesis Testing
	3. Exporting results to LaTex
*******************************************************************/


*******************************************************************
* 1. Commenting in Stata
*******************************************************************

* (1) Full-line comment using *
* (2) End-of-line comment using //
* (3) Block comment using /* ... */



*******************************************************************
* 2. Load Dataset
*******************************************************************

* Install bcuse if not already installed
ssc install bcuse 

* Load Wooldridge dataset
bcuse bwght, clear // import the dataset

* Inspect data
br in 1/10
summarize
summarize bwght cigs motheduc
sum bwght if cigs>0
tab cigs
misstable summarize




*******************************************************************
* 3. Regression Analysis
*******************************************************************

* Model:
* bwght_i = β1 + β2*cigs_i + β3*parity_i + β4*faminc_i + β5*motheduc_i + β6*fatheduc_i + ε_i
drop if missing(bwght, cigs, parity, faminc, motheduc, fatheduc)
reg bwght cigs parity faminc motheduc fatheduc

* Interpretation:
* - Coefficient on cigs (β2) captures ...
* - t-statistic and p-value test H0: β2 = 0


*******************************************************************
* 4.1 Hypothesis Testing: significance of cigs
*******************************************************************

* Null and alternative hypotheses:
*   H0: β_cigs = 0
*   H1: β_cigs ≠ 0

* Stata automatically provides t-statistic and p-value for this test

* Perform a specific test:
test cigs = 0

* This performs an F-test (which equals t^2 when there's one restriction).
display(sqrt(29.17))


*******************************************************************
* 4.2 Decision Rule
*******************************************************************

* If |t| > t_crit, reject H0.
* For α = 0.05 and large n, t_crit ≈ 1.96 (two-sided test).


*******************************************************************
* 5.1 Hypothesis Testing: significance of motheduc and fatheduc
*******************************************************************

* Null and alternative hypotheses:
*   H0: β_motheduc = β_fatheduc = 0
*   H1: not H0


* Perform the F test:
test motheduc fatheduc


*If we want manually to contruct the F statistic

*1. Run restricted model and get sse
reg bwght cigs parity faminc
scalar sse_r = e(rss)

*2. Run unrestricted model and get sse
regress bwght cigs parity faminc motheduc fatheduc
scalar sse = e(rss)
scalar df = 1191 - 6

*3. Compute statistic
scalar F = ((sse_r - sse)/2) / (sse/df)
display F


*******************************************************************
* 5.2 Decision Rule
*******************************************************************

* If F > F_crit, reject H0.
display invFtail(2, 1185, 0.05)
* For α = 0.05, F_crit ≈ 3.

local p_value Ftail(2, 1185, F)
display "P-value: "`p_value'


*********************
* 6. Export Results to LaTeX
*********************

* You can export regression results using outreg2 or esttab.

* Install if needed:
ssc install outreg2

* You can set manually your directory
cd "/Users/luciasauer/Desktop/Econometrics_TA/bse_econometrics/TA3"

*or obtain the directory where the do file is stored.
local dofile_path = "`c(currentdir)'"
cd "`dofile_path'"

outreg2 using "regression_output.tex", replace ctitle("OLS Results") dec(3)

* Alternative with esttab:
ssc install estout

esttab using "regression_output.tex", replace se star(* 0.10 ** 0.05 *** 0.01) label


