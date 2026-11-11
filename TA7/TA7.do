/*******************************************************************
TA Session 7 - Matching
Author: Lucia Sauer
Contact: lucia.sauer@bse.eu
Date: 2026-11-18
Dataset: NSW job-training program (LaLonde 1986; Dehejia & Wahba 1999)
         + CPS comparison group (nsw_cps.dta)

Question: Did the NSW job-training program raise earnings in 1978?
          We compare participants with non-participants from a survey
          (CPS): observational data, no coin flip.

Contents:
	0. Setup
	1. Was the treatment randomly assigned? (balance check)
	2. Propensity score and the balancing property     (pscore)
	3. Matching estimators of the ATT                  (psmatch2)
	   3.1 Nearest neighbour on X (Mahalanobis)
	   3.2 Nearest neighbour on the pscore, k = 1
	   3.3 Nearest neighbour on the pscore, k = 5
	   3.4 Radius on the pscore
	   3.5 Kernel on the pscore (+ bootstrap SE)
	4. Results table and covariate balance (love plot)
	5. Propensity score distribution before and after matching
	6. The answer we know: the NSW was an experiment

One package per job:
	- pscore   (Becker & Ichino): estimate the pscore and TEST the
	           balancing property block by block.
	- psmatch2 (Leuven & Sianesi): ALL the matching estimators.
	- pstest   (comes with psmatch2): covariate balance after matching.

The file can be run all at once or section by section (in order):
every section only uses variables, globals, scalars and programs
created by the previous ones.
*******************************************************************/


* -------------------------------------------------------------------
* 0) Setup
* -------------------------------------------------------------------
clear all
cap cls
cap set more off
set seed 669

*** Packages (install once)
* ssc install estout            // estpost / esttab: tables
* ssc install psmatch2          // psmatch2 + pstest
* net describe st0026_2, from(http://www.stata-journal.com/software/sj5-3)
* net install  st0026_2         // pscore

use nsw_cps, clear
tab sample                      // 1 = NSW participant, 2 = NSW experimental control, 3 = CPS adult

* We start as a researcher WITHOUT an experiment: participants vs CPS.
* (The experimental controls, sample == 2, come back in section 6.)
drop if sample == 2

* Covariates (Dehejia & Wahba 1999)
gen agesq  = age^2
gen educsq = educ^2
gen u74    = (re74 == 0)        // =1 if no earnings in 1974 (unemployed)
gen u75    = (re75 == 0)        // =1 if no earnings in 1975
global X age agesq educ educsq married nodegree black hisp re74 re75 u74 u75


* -------------------------------------------------------------------
* 1) Was the treatment randomly assigned? Balance check
* -------------------------------------------------------------------
* For each covariate: H0: E[X | D=1] = E[X | D=0] (Welch t-test).
* If D were random we would reject ~5% of the time. Here almost always.
estpost ttest age educ black hisp married nodegree re74 re75 u74 u75, by(treat) unequal
esttab ., cells("mu_2(fmt(2) label(Participants)) mu_1(fmt(2) label(CPS)) p(fmt(3) label(p-value))") ///
	noobs nonumber title("Balance before matching")

* Naive comparison of mean 1978 earnings
reg re78 treat, robust          // about -8,498: CPS adults are very different people


* -------------------------------------------------------------------
* 2) Propensity score and the balancing property (pscore)
* -------------------------------------------------------------------
* pscore estimates p(X) = P(D=1|X) with a logit, keeps the common
* support, splits p-hat into blocks and tests, block by block, that
* every X has the same mean for treated and controls.
*   pscore(myscore)  : save p-hat in myscore
*   blockid(myblock) : save the block of each unit
*   comsup           : create comsup = 1 if p-hat is within [min, max] of
*                      the participants' p-hat (it does NOT drop anyone)
*   level(0.005)     : significance level of the balancing tests

* First attempt: fails ("agesq not balanced in block 4", "re74 ... block 6")
foreach v in ps_try bl_try comsup {
	cap drop `v'
}
pscore treat $X, pscore(ps_try) blockid(bl_try) comsup logit level(0.005)
drop ps_try bl_try comsup

* Second attempt: more flexible in age, and education x past earnings
foreach v in agecu educ_re74 myscore myblock comsup {
	cap drop `v'                // one at a time: cap drop a b c drops nothing if one is missing
}
gen agecu     = age^3
gen educ_re74 = educ*re74
global X2 $X agecu educ_re74
pscore treat $X2, pscore(myscore) blockid(myblock) comsup logit level(0.005)
* -> "The balancing property is satisfied"

tab comsup treat                // 12,136 CPS adults below the lowest participant
tab myblock treat               // participants and CPS adults in each block


* -------------------------------------------------------------------
* 3) Matching estimators of the ATT (psmatch2)
* -------------------------------------------------------------------
* psmatch2 treat <if> , <method options> outcome(re78)
*   reports the ATT and creates
*   _weight : how much each unit counts in the matched sample
*             (unused controls: 0 or missing)
*   _pscore, _treated, _support
*   These variables are OVERWRITTEN by the next psmatch2, so after each
*   method we copy _weight into w_<method>.
*
* COMMON SUPPORT. Two different trims, we use both:
*   if comsup == 1 : the common support from pscore (section 2). It drops
*                    the 12,136 CPS adults with p-hat below every participant.
*                    pscore only CREATES the variable comsup; we must apply it.
*                    Without it, radius and kernel would give weight to those
*                    CPS adults (p-hat ~ 0 is within r or h of low-p-hat
*                    participants).
*   common         : psmatch2's own trim: drops PARTICIPANTS whose p-hat is
*                    above the highest (or below the lowest) control p-hat.
* All methods are run on the same sample (comsup == 1).

* 3.0 Where results are stored -------------------------------------
*   res : one row per method (ATT, SE, sample sizes, mean |bias|)
*   bal : one row per method x covariate (standardized % bias)
cap postclose res
cap postclose bal
postfile res str32 method att se n_treated n_controls mean_bias using matching_results, replace
postfile bal str32 method str12 variable bias using matching_balance, replace

* save_att <method> <att> <se>: posts the ATT and the balance summary of
* the last psmatch2 (uses _weight and pstest)
capture program drop save_att
program define save_att
	args method att se
	qui count if _treated == 1 & _weight < .
	local nt = r(N)
	qui count if _treated == 0 & _weight > 0 & _weight < .
	local nc = r(N)
	qui pstest $X, both
	post res ("`method'") (`att') (`se') (`nt') (`nc') (r(meanbiasaft))
end

* save_balance <method> <weight>: standardized % bias of each X,
*   100 * (mean_T - mean_C) / sqrt((var_T + var_C) / 2)
*   means weighted by <weight>; variances from the unmatched sample (as pstest)
capture program drop save_balance
program define save_balance
	args method weight
	foreach v of global X {
		qui sum `v' if treat == 1
		local vt = r(Var)
		qui sum `v' if treat == 0
		local vc = r(Var)
		qui sum `v' [aw = `weight'] if treat == 1 & `weight' < . & `weight' > 0
		local mt = r(mean)
		qui sum `v' [aw = `weight'] if treat == 0 & `weight' < . & `weight' > 0
		local mc = r(mean)
		post bal ("`method'") ("`v'") (100 * (`mt' - `mc') / sqrt((`vt' + `vc') / 2))
	}
end

* Before matching: everybody with weight 1
cap drop w_before
gen w_before = 1
save_balance "Before matching" w_before

* 3.1 Nearest neighbour on the covariates (Mahalanobis distance) ----
psmatch2 treat if comsup == 1, mahalanobis($X) outcome(re78)
save_att "NN on X (Mahalanobis)" `=r(att)' `=r(seatt)'
save_balance "NN on X (Mahalanobis)" _weight
cap drop w_mahal
gen w_mahal = _weight

* 3.2 Nearest neighbour on the pscore, 1 neighbour (with replacement)
psmatch2 treat if comsup == 1, pscore(myscore) outcome(re78) neighbor(1) common
save_att "NN on pscore, k = 1" `=r(att)' `=r(seatt)'
save_balance "NN on pscore, k = 1" _weight
cap drop w_nn1
gen w_nn1 = _weight

* 3.3 Nearest neighbour on the pscore, 5 neighbours ------------------
psmatch2 treat if comsup == 1, pscore(myscore) outcome(re78) neighbor(5) common
save_att "NN on pscore, k = 5" `=r(att)' `=r(seatt)'
save_balance "NN on pscore, k = 5" _weight
cap drop w_nn5
gen w_nn5 = _weight

* 3.4 Radius: all controls with |p_i - p_j| < 0.01, equal weights ----
psmatch2 treat if comsup == 1, pscore(myscore) outcome(re78) radius caliper(0.01) common
save_att "Radius (r = 0.01)" `=r(att)' `=r(seatt)'
save_balance "Radius (r = 0.01)" _weight
cap drop w_radius
gen w_radius = _weight

* 3.5 Kernel: all controls, weights falling with |p_i - p_j| ---------
*     (Epanechnikov kernel, bandwidth 0.06 = psmatch2 default)
psmatch2 treat if comsup == 1, pscore(myscore) outcome(re78) kernel common
scalar att_k = r(att)
save_balance "Kernel" _weight
cap drop w_kernel
gen w_kernel = _weight

* Kernel matching has no valid analytical SE: bootstrap it. Each
* replication re-estimates the pscore, the common support AND the ATT
* on a resampled dataset.
capture program drop kernel_att
program define kernel_att, rclass
	capture drop ps_b
	capture drop cs_b
	qui logit treat $X2
	qui predict ps_b, pr
	qui sum ps_b if treat == 1
	qui gen cs_b = inrange(ps_b, r(min), r(max))       // common support, as pscore
	qui psmatch2 treat if cs_b == 1, pscore(ps_b) outcome(re78) kernel common
	return scalar att = r(att)
end
bootstrap att = r(att), reps(50) seed(669) nodots: kernel_att
scalar se_k = _se[att]

* re-run the kernel on the original data to restore _weight, then save
qui psmatch2 treat if comsup == 1, pscore(myscore) outcome(re78) kernel common
save_att "Kernel (bootstrap SE)" `=att_k' `=se_k'

* 3.6 Close the result files (run this before section 4) -------------
postclose res
postclose bal


* -------------------------------------------------------------------
* 4) Results table and covariate balance (love plot)
* -------------------------------------------------------------------
* NOTE: psmatch2 SEs ignore that the pscore is estimated; the kernel SE
* is bootstrapped. We keep the main data in memory with preserve/restore.
preserve
use matching_results, clear
list method att se n_treated n_controls mean_bias, noobs sep(0) abbreviate(12)
export delimited using matching_results.csv, replace

* The "winner": the method with the smallest mean |standardized bias|
sort mean_bias
di as result "Best balance: " method[1] " (mean |bias| = " %4.1f mean_bias[1] "%)"

* Love plot: |standardized bias| of each covariate, by method
use matching_balance, clear
export delimited using matching_balance.csv, replace
gen absbias = abs(bias)
encode variable, gen(var_id)
twoway (scatter var_id absbias if method == "Before matching",        msymbol(T) mcolor(gs10)) ///
       (scatter var_id absbias if method == "NN on pscore, k = 1",    msymbol(O) mcolor(orange)) ///
       (scatter var_id absbias if method == "Kernel",                 msymbol(S) mcolor(purple)) ///
       (scatter var_id absbias if method == "NN on X (Mahalanobis)",  msymbol(D) mcolor(teal)), ///
	ylabel(1(1)12, valuelabel angle(0)) xline(10, lpattern(dash)) ///
	xtitle("|standardized bias| (%)") ytitle("") ///
	legend(order(1 "Before" 2 "NN p-score" 3 "Kernel" 4 "NN on X (Mahalanobis)") rows(1)) ///
	name(loveplot, replace)
restore


* -------------------------------------------------------------------
* 5) Propensity score distribution before and after matching
* -------------------------------------------------------------------
* Before: participants vs ALL CPS adults (myscore, from pscore).
* After : participants vs the MATCHED CPS adults, each control weighted
*         by how much it is used (w_<method> = _weight of that method).
* If matching worked, the two densities should (almost) overlap.

* 5.1 Before matching (all units)
twoway (kdensity myscore if treat == 1, lcolor(orange) lwidth(medthick)) ///
       (kdensity myscore if treat == 0, lcolor(teal) lwidth(medthick)), ///
	legend(order(1 "Participants" 2 "CPS adults") rows(1)) ///
	xtitle("Propensity score") ytitle("Density") title("Before matching") ///
	name(ps_before, replace)

* 5.2 After matching, one graph per method (same code, different weight)
foreach m in mahal nn1 nn5 radius kernel {
	twoway (kdensity myscore if treat == 1 & w_`m' < . & w_`m' > 0 [aw = w_`m'], lcolor(orange) lwidth(medthick)) ///
	       (kdensity myscore if treat == 0 & w_`m' < . & w_`m' > 0 [aw = w_`m'], lcolor(teal) lwidth(medthick)), ///
		legend(order(1 "Participants" 2 "Matched CPS") rows(1)) ///
		xtitle("Propensity score") ytitle("Density") title("After: `m'") ///
		name(ps_`m', replace)
}

* 5.3 All together
graph combine ps_before ps_mahal ps_nn1 ps_nn5 ps_radius ps_kernel, ///
	cols(3) ycommon name(ps_before_after, replace)

* Quick alternative that comes with psmatch2: histogram of the pscore by
* treatment and support status of the LAST psmatch2 (here: kernel).
* It shows overlap, but it is NOT weighted by the matching.
psgraph, bin(20) name(psgraph, replace)

* For the slides: p-hat, treatment and matching weights of each unit
preserve
keep if comsup == 1
keep treat myscore w_mahal w_nn1 w_nn5 w_radius w_kernel
export delimited using matching_weights.csv, replace
restore


* -------------------------------------------------------------------
* 6) The answer we know: the NSW was an experiment
* -------------------------------------------------------------------
* Participants were randomly drawn from the applicants; the applicants
* randomized out (sample == 2) are an experimental control group.
use nsw_cps, clear
gen agesq  = age^2
gen educsq = educ^2
gen u74    = (re74 == 0)
gen u75    = (re75 == 0)

reg re78 treat if sample <= 2, robust          // experiment: the benchmark
eststo exp_bench
reg re78 treat if sample != 2, robust          // naive: participants vs CPS
eststo naive
reg re78 treat $X if sample != 2, robust       // OLS + X: participants vs CPS
eststo ols
esttab exp_bench naive ols, se star(* 0.10 ** 0.05 *** 0.01) keep(treat) ///
	b(%9.0f) se(%9.0f) mtitles("Experiment" "Naive (CPS)" "OLS + X (CPS)") ///
	title("Effect of NSW training on 1978 earnings")
