/*******************************************************************
TA Session 6 - Non Spherical Disturbances
Author: Lucia Sauer
Contact: lucia.sauer@bse.eu
Date: 2025-11-07
Dataset: Ham and LaLonde (1996), https://www.jstor.org/stable/2171928. 

Objective: We are interested in evaluating the effect of a job training program on labor earnings.

Contents: 
	1. RCT
	2. ATE
	3. Exact Matching
	4. Propensity Score Matching
	5. Clustered SE
*******************************************************************/


* -------------------------------------------------------------------
* Clear workspace and set up environment
* -------------------------------------------------------------------
clear all          // Clears all data from memory
cls                // Clears the command window
cap set more off   // Turns off --more-- prompt
set maxvar 32000   // Sets maximum number of variables (for larger datasets)

* Load the dataset
use TA6, clear

* Initial data exploration
describe

* Inspect outcome variable (real earnings in 1978) by treatment status
tabulate train, summarize(re78) means standard 

* -------------------------------------------------------------------
* Define Variables
* -------------------------------------------------------------------

* Outcome variable: real earnings in 1978
gen earnings = re78 

* Treatment variable: participation in job training
gen treat = train 

* -------------------------------------------------------------------
* 1) Difference in Means: Two-sample t-test
* -------------------------------------------------------------------

* Estimate summary statistics by treatment group
eststo treat_earnings: estpost summarize earnings if treat == 1
eststo contr_earnings: estpost summarize earnings if treat == 0

* Perform two-sample t-test with unequal variances
eststo diff_earnings: estpost ttest earnings, by(treat) unequal

* Display results of the t-test in a comparative table
esttab treat_earnings contr_earnings diff_earnings, ///
    cells("mean(pattern(1 1 0) fmt(2)) b(star pattern(0 0 1) fmt(2))") ///
    mtitles("Treatment" "Control" "Difference") ///
    title("Two-sample t-test: Difference in Means")


* -------------------------------------------------------------------
* 3) Regression Analysis
* -------------------------------------------------------------------

* Simple regression of earnings on treatment
reg earnings treat 
eststo reg_simple 

* Interpretation:
* - The coefficient on `treat` represents the Average Treatment Effect (ATE).
* - This is the mean difference in earnings between trained and untrained individuals.


* -------------------------------------------------------------------
* 4) Adding Covariates to Control for Confounding
* -------------------------------------------------------------------

* Covariates for analysis
global xvars re74 re75 age agesq nodegree married black hisp

* Regression with additional control variables
reg earnings treat $xvars  
eststo reg_covariates

* Compare results of regressions with and without covariates
esttab reg_simple reg_covariates, se star keep(treat) ///
    stats(r2) mtitles("Simple" "+Controls") ///
    title("ATE Comparison: Simple vs. +Controls")
	
* -------------------------------------------------------------------
* Notes:
* - The `treat` coefficient in regression represents the ATE (Average Treatment Effect).
* - If randomization is successful, adding covariates should not substantially change the ATE, it should increase precision by FWL
* -------------------------------------------------------------------


* -------------------------------------------------------------------
* 5) Covariate Balance Check
* -------------------------------------------------------------------

* Summary statistics for covariates by treatment status
tabstat earnings treat $xvars, statistics(n mean sd min max) columns(statistics)
bysort treat: tabstat earnings $xvars, statistics(mean sd) columns(statistics)

* Interpretation:
* - Compare the means and standard deviations of covariates between treatment and control groups.
* - If treatment was assigned randomly, we expect minimal differences between groups.
* - Any systematic differences could indicate potential confounding factors.


estpost ttest $xvars, by(treat) unequal

	

* -------------------------------------------------------------------
* 5) Estimating ATE and ATT with Regression Adjustment (RA)
* -------------------------------------------------------------------

/* 
   Purpose:
   - The `teffects ra` command estimates treatment effects by creating 
     treatment-specific predicted outcomes, then calculating the average 
     treatment effect (ATE) and the average treatment effect on the treated (ATT).
   - This approach allows flexibility for continuous, binary, count, 
     or nonnegative outcomes.
*/

/* -------------------------------------------------------------------
   ATE (Average Treatment Effect):
   - ATE estimates the effect of training on earnings for the entire population,
     comparing the expected earnings if everyone received training 
     vs. if no one received training.
   ------------------------------------------------------------------- */

* Estimate ATE without covariates (baseline)
teffects ra (earnings, linear) (treat)

* Estimate ATE with covariates to control for confounding factors
teffects ra (earnings $xvars, linear) (treat)

* Interpretation:
* - If everyone received training, average earnings would increase by 1.54 compared to  an average of 4.57 if no one received training.
* - The previous results show the overall effect of training on women's earnings. However, we may also be interested in understanding how much earnings increased specifically for women who actually participated in the training program.


/* -------------------------------------------------------------------
   ATT (Average Treatment Effect on the Treated):
   - ATT estimates the effect of training specifically for those 
     who actually received it, comparing their observed earnings 
     to what they would have earned without the training.
  
*/
* Estimate ATT with covariates, focused on treated group
teffects ra (earnings $xvars, linear) (treat), atet


* Interpretation:
* - Average earnings are 1.76 higher for women who received training, compared to an estimated average of 4.48 if these same women had not participated.
* - The ATT differs from the ATE because the characteristics (covariates) of women who received training differ from those of women who did not, affecting the estimated impact.



* -------------------------------------------------------------------
* Matching
* -------------------------------------------------------------------


*** Packages to be installed 
	* estout - Making regression tables
	*ssc install estout 
	* psmatch2 - Perform propensity score matching 
	*ssc install psmatch2
	* pscore - Estimation of average treatment effects by Becker and Ichino
	*help st0026_2
	* cem - Module to perform coarsened exact matching 
	*ssc install cem
	


* --------------------------------------------------------------
* Method 1: Mahalanobis Distance (covariates matching)
* --------------------------------------------------------------

* nearest neighbour (1 neighbour by default)
teffects nnmatch (earnings $xvars) (treat)

* more neighbours
teffects nnmatch (earnings $xvars) (treat), nneighbor(3)

* exact matching for some variables
teffects nnmatch (earnings $xvars) (treat), nneighbor(3) ematch(black hisp)

* bias adjustment for large sample
teffects nnmatch (earnings $xvars) (treat), biasadj(age agesq re74 re75)




* --------------------------------------------------------------
* Method 2: Propensity Score Matching (Pr(T=1|X))
* --------------------------------------------------------------


* average treatment effect (ATE)
teffects psmatch (earnings) (treat $xvars)


* average treatment effect on the treated (ATT)
teffects psmatch (earnings) (treat $xvars), atet

* graph overlap - common support
teffects psmatch (earnings) (treat $xvars), generate(neaer_obs)
teoverlap
drop neaer_obs*

* Interpretation:
* - Graph shows the distribution of pscores for treatment and control groups.
* - Visually assesses the common support region.
* - This overlap indicates that the matched samples are comparable, which is critical for valid ATT estimation.
* - Little overlap indicates that some treated individuals don't have comparable controls


* --------------------------------------------------------------
* Balancing property
* --------------------------------------------------------------
*The pscore algorithm estimates the probability of receiving treatment given the covariates — the propensity score — and checks whether, conditional on that score, the treated and control groups look similar in X.
*If balance holds within each score block, we can proceed to match treated and controls with comparable probabilities, making the observational study look like a randomized experiment.


pscore treat $xvars, pscore(myscore) blockid(myblock) level(0.005) ///
				comsup logit

* Step 1: we separate units in blocks to ensure the mean of pscore is not different for treated and untreated in each of these blocks.
* Step 2: in each of these blocks, not only the pscore is similar but the X characteristics on which we match are also similar (conditional independence). 
* Blockid: contains treated and untreated units comparable in terms of covariates.


* ONLY IF THE BALANCING PROPERTY IS SATISFIED

* --------------------------------------------------------------
* Treatment effects using propensity score matching
* --------------------------------------------------------------

* nearest neighbour
attnd earnings treat $xvars, comsup logit
* comsup restricts the computation of the ATT to the region of common support


* radius matching
attr earnings treat $xvars, comsup logit // 0.01 by default
attr earnings treat $xvars, comsup logit radius(0.001)
attr earnings treat $xvars, comsup logit radius(0.0001)


* kernel matching
attk earnings treat $xvars, comsup logit

* kernel matching with bootstrapping
attk earnings treat $xvars, comsup logit boot reps(100) dots



* --------------------------------------------------------------
* Graph quality of matching
* --------------------------------------------------------------
ssc install  psmatch2
psmatch2 treat, out(earnings) pscore(myscore) neighbor(2) common
*sort _treated _pscore

twoway (kdensity myscore if treat == 1 ) ///
		(kdensity myscore if treat == 0), ///
legend(order(1 "treated" 2 "untreated")) ///
xtitle("propensity score before matching") ytitle("density") ///
name(before, replace)
 
twoway (kdensity myscore if treat == 1 [aw = _weight]) ///
		(kdensity myscore if treat == 0 [aw = _weight]), ///
legend(order(1 "treated" 2 "untreated")) ///
xtitle("propensity score after matching ") ytitle("density") ///
name(after, replace)

graph combine before after


