/*******************************************************************
TA Session 5 - Non Spherical Disturbances
Author: Lucia Sauer
Contact: lucia.sauer@bse.eu
Date: 2025-10-22
Dataset: hprice3 (Wooldridge)

Contents: 
	1. Visual inspection of heteroskedasticity
	2. BP Test
	3. Robust SE
	4. Boostrap SE
	5. Clustered SE
*******************************************************************/

clear all
bcuse hprice3, clear
describe

regress price area rooms

* Residuals vs predictor plot (check heteroskedasticity)
rvpplot area


* Breush Pagan Test
* ===================
* - Joint significance approach with flexible test equation specification
* - Requires normality assumption for OLS in small sample (F-stat); or 
* 	asymptotic normality in larger samples (LM-stat).


*1. Run the main regression
regress price area rooms


*2. Obtain the squared OLS residuals 
predict uhat, resid
gen uhat_sq = uhat^2

*3. Run the auxiliary regression
regress uhat_sq area rooms

// Check F-stat and associated p-value: if p < 0.05, we reject the null (homoskedasticity)

* Perform the Breusch-Pagan test using F-stat
regress price area rooms
hettest, rhs fstat

* Asymptotics: Lagrange multiplier stats
hettest

* ===================================================
* Solutions
* ===================================================

regress price area rooms
estimates store OLS


* 1) ROBUST SE
regress price area rooms, vce(robust)
estimates store OLS_HC

* 2) BOOTSTRAP SE
bootstrap, reps(500) seed(123): regress price area rooms
estimates store OLS_BOOT


* ===================================================
*Cluster Data
* ===================================================

twoway (scatter uhat area, mcolor(gs10)) ///
       (lfit uhat area, lcolor(black)), ///
       by(nbh, total title("Residuals vs area by neighborhood"))


* 4) CLUSTER-ROBUST SE
*Cluster by 'neighborhood'
regress price area rooms, vce(cluster nbh)
estimates store OLS_CL




coefplot (OLS, label("Classical SE")) ///
         (OLS_HC, label("Robust SE")) ///
         (OLS_BOOT, label("Bootstrap SE")), ///
    keep(area) ///
    xline(0) ///
    ciopts(recast(rcap) lwidth(medthick)) ///
    msymbol(O) mcolor(navy) ///
    xlabel(, labsize(medium)) ///
    ytitle("Coefficient on area") ///
    title("95% Confidence Intervals across SE types") ///
    legend()

