*------------------------------------------------------------------------------*
* Stats 506, Fall 2018 
* Problem Set 2, Question 1
* 
* Estimate national totals for select types energy usage using the RECS 2015
* data available below.
*
* Author: James Henderson
* Updated: October 19, 2018
*
*------------------------------------------------------------------------------*

* Set up: ----------------------------------------------------------------------

version 14.2
log using ps2_q1.log, text replace


// data prep
import delimited recs2015_public_v3.csv

preserve

// We will use these variable names repeatedly.
local vars = "kwh cufeetng gallonlp gallonfo"

// keep primary energy use variables
keep doeid nweight `vars'
save recs2015_fuels.dta, replace

// generate contributions to estimate for national total

foreach var in `vars' {
  generate t`var'=`var'*nweight
}

// compute point estimates for national totals
keep doeid t*
collapse (sum) t*

// add a fake variable to merge on later and save
generate fid=0
save recs2015_fuels_petotal.dta, replace

// keep replicate weights and reshape to long
restore
keep doeid brrwt1-brrwt96

reshape long brrwt, i(doeid) j(repl)
// save recs2015_brrwt_long.dta // if needed again later

// merge together
merge m:1 doeid using recs2015_fuels.dta

// compute replicate estimates 
foreach var in `vars' {
  generate t`var'_r=`var'*brrwt
}

collapse (sum) t*_r, by(repl)

// merge against point estimates using fid

generate fid=0
merge m:1 fid using recs2015_fuels_petotal.dta

// compute residuals
foreach var in `vars' {
  generate rsq_`var'= (t`var'-t`var'_r)^2
}

// collapse to point estimates and standard errors
drop *_r
collapse (first) t* (mean) rsq_*

// Fay coefficient
foreach var in `vars' {
  replace rsq_`var' = 2*sqrt(rsq_`var')
}

// reshape and output as csv
generate fid=0
reshape long t rsq_, i(fid) j(fuel) string

rename t total
rename rsq_ std_error
drop fid

export delimited recs2015_usage.csv, replace

log close
*80: ---------------------------------------------------------------------------