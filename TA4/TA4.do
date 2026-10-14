/*==========================================================================
  TA Session 4 - Introduction to Stata and F tests
  Course  : Econometrics, Barcelona School of Economics
  Author  : Lucia Sauer (lucia.sauer@bse.eu)
  Updated : 2025-10-15

  Question: What explains college GPA? Do working hours matter once we
            control for high-school GPA, skipped lectures, partner status
            and drinking?
  Data    : gpa1 (Wooldridge), 141 students

  Contents:
    0. Setup
    1. Load the data
    2. Explore the data
    3. Dummies: job19, job20 and the base category
    4. Regression and stored results
    5. Global F test: are all the slopes zero?
    6. Joint F test: are job19 and job20 jointly significant?
    7. Regression table in LaTeX (esttab)

  Before running: copy this file (TA4_copy.do) and edit the copy only.
==========================================================================*/


*** 0. Setup ***************************************************************

clear all
set more off


*** 1. Load the data *******************************************************

* bcuse is user-written: install it only if it is missing
capture which bcuse
if _rc ssc install bcuse

bcuse gpa1, clear


*** 2. Explore the data ****************************************************

describe colGPA hsGPA job19 job20 skipped bgfriend alcohol
summarize colGPA hsGPA job19 job20 skipped bgfriend alcohol
list colGPA hsGPA job19 job20 skipped bgfriend alcohol in 1/5

* browse                     // opens the Data Browser (read-only)

* if / by: the same command on a subset of rows
summarize colGPA if bgfriend == 1
bysort bgfriend: summarize colGPA

* r-class results: summarize stores them in r()
summarize colGPA
return list
display "Mean college GPA = " r(mean)


*** 3. Dummies: job19, job20 and the base category *************************

* Not a dummy trap: students without a job have job19 = job20 = 0,
* so they are the base category (59 students)
tabulate job19 job20

generate byte nojob = (job19 == 0 & job20 == 0)
tabulate nojob

* Adding nojob as well would make nojob + job19 + job20 = 1 = the constant


*** 4. Regression and stored results ***************************************

* colGPA_i = b1 + b2*hsGPA_i + b3*job19_i + b4*job20_i
*            + b5*skipped_i + b6*bgfriend_i + b7*alcohol_i + e_i
regress colGPA hsGPA job19 job20 skipped bgfriend alcohol

* e-class results: regress stores them in e()
ereturn list

* Save them in scalars: the next regress overwrites e()
scalar SSE    = e(rss)        // residual sum of squares
scalar n_obs  = e(N)          // n = 141
scalar df_res = e(df_r)       // n - K = 134
scalar F_stata = e(F)         // F(6, 134) reported in the output


*** 5. Global F test: are all the slopes zero? *****************************

* H0: b2 = b3 = b4 = b5 = b6 = b7 = 0      (q = 6 restrictions)
* H1: at least one of them is different from 0
* F = [(RSSE - SSE)/q] / [SSE/(n - K)]  ~  F(q, n - K) under H0

* Restricted model: only a constant, so the fitted value is the mean
summarize colGPA
scalar colgpa_mean = r(mean)

* RSSE = sum of (colGPA - mean)^2. sum() inside generate is a running sum,
* so we use egen total() to get the column total
egen double rsse_total = total((colGPA - colgpa_mean)^2)
scalar RSSE = rsse_total[1]

scalar F_global = ((RSSE - SSE) / 6) / (SSE / df_res)

display "RSSE = " RSSE "   SSE = " SSE
display "Manual F = " F_global "   Stata F = " F_stata

* Critical value at 5% and p-value
scalar Fcrit_global = invFtail(6, df_res, 0.05)
scalar p_global     = Ftail(6, df_res, F_global)
display "Critical value (5%) = " Fcrit_global
display "p-value = " p_global

* Decision: F = 7.74 > 2.17 and p < 0.05, so we reject H0


*** 6. Joint F test: are job19 and job20 jointly significant? **************

* H0: b3 = b4 = 0                          (q = 2 restrictions)
* H1: b3 != 0 or b4 != 0

* 6.1 By hand: restricted vs unrestricted model

* Restricted model: impose H0 by dropping job19 and job20
regress colGPA hsGPA skipped bgfriend alcohol
scalar SSE_r = e(rss)

* Unrestricted model, run last so that e(df_r) refers to it
regress colGPA hsGPA job19 job20 skipped bgfriend alcohol
scalar SSE_u = e(rss)

scalar F_joint     = ((SSE_r - SSE_u) / 2) / (SSE_u / e(df_r))
scalar Fcrit_joint = invFtail(2, e(df_r), 0.05)
scalar p_joint     = Ftail(2, e(df_r), F_joint)

display "RSSE = " SSE_r "   SSE = " SSE_u "   F = " F_joint
display "Critical value (5%) = " Fcrit_joint
display "p-value = " p_joint

* 6.2 The one-line version, right after the unrestricted regression
test job19 job20

* Decision: F = 0.49 < 3.06 and p = 0.61 > 0.05, so we cannot reject H0


*** 7. Regression table in LaTeX (esttab) **********************************

* Run once: the estout package provides eststo and esttab
capture which esttab
if _rc ssc install estout

* The table prints variable labels, so write them as they should appear in
* the paper. Math goes between $ $ (a $ followed by a letter is a global
* macro in Stata: write \(p\) instead of $p$)
label variable colGPA   "College GPA"
label variable hsGPA    "High-school GPA"
label variable job19    "Works $\leq$ 19 h/week"
label variable job20    "Works $\geq$ 20 h/week"
label variable skipped  "Lectures skipped / week"
label variable bgfriend "Has a partner"
label variable alcohol  "Days drinking / week"

* Estimate and store three nested models: one column each
eststo clear
eststo m1: regress colGPA hsGPA skipped
eststo m2: regress colGPA hsGPA skipped bgfriend alcohol
eststo m3: regress colGPA hsGPA job19 job20 skipped bgfriend alcohol

* Add the joint-test p-value to model 3, so it can be reported in the table
test job19 job20
estadd scalar p_jobs = r(p)

* Export: booktabs rules, labels, 3 decimals, stars, decimal alignment
* (needs \usepackage{booktabs} and \usepackage{dcolumn} in main.tex)
esttab m1 m2 m3 using "regression_table.tex", replace           ///
    booktabs label b(3) se(3)                                   ///
    star(* 0.10 ** 0.05 *** 0.01)                               ///
    alignment(D{.}{.}{-1})                                      ///
    mgroups("Dependent variable: College GPA", pattern(1 0 0)   ///
            prefix(\multicolumn{@span}{c}{) suffix(})           ///
            span erepeat(\cmidrule(lr){@span}))                 ///
    mtitles("Baseline" "Restricted" "Unrestricted")             ///
    stats(N r2 r2_a F p_jobs, fmt(0 3 3 2 3)                    ///
          layout("\multicolumn{1}{c}{@}" @ @ @ @)               ///
          labels("Observations" "R$^2$" "Adjusted R$^2$"        ///
                 "F statistic" "Jobs jointly = 0 (\(p\)-value)")) ///
    title("Determinants of college GPA\label{tab:gpa}")         ///
    collabels(none) nogaps

* Same table in the Results window, to check it before opening LaTeX
esttab m1 m2 m3, label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Restricted" "Unrestricted")             ///
    stats(N r2 r2_a F p_jobs, fmt(0 3 3 2 3))

* In main.tex:  \input{regression_table.tex}   and cite it with \ref{tab:gpa}
