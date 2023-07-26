********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: Global Sample - Firm Level Analyses							****
********************************************************************************

* Preliminaries
clear all
set more off
set maxvar 15000

* Seed 
set seed 91011

* Directory
local directory = "...\Global_Sample" /* Please insert/adjust directory path */

********************************************************************************
*** Our Approach to Computing Corporate Carbon Damages						****
********************************************************************************

/* We measure corporate carbon damages as the expected monetary value of each company's climate damages associated with its GHG emissions, scaled by an operational measure. 
Specifically, (unscaled) corporate carbon damages are the product of firm-level Scope 1 emissions measured in tCO2e and the monetary value of the damages associated with the release of an additional ton of CO2, also known as the social cost of carbon (SCC).
In order to give a sense of scale, we report corporate carbon damages as a share of the firms' operating profits or alternatively its revenues. 
When scaling carbon damages by operating income, we keep only firms for which operating income is positive. 
To reduce the influence of extreme observations, we truncate scaled corporate carbon damages that are below the 1st percentile or above the 99th percentile. 
To reflect the uncertainties in estimating climate damages, we provide estimates for three different established values of the SCC: 
(i) $51 per tCO2e, which matches the Obama administration's estimate and the Biden administration's temporary one; (ii) $190 per tCO2e, which follows the US Environmental Protection Agency's (EPA) estimate in its recent November 2022 proposal; and $250 per tCO2e based on recent research. */

********************************************************************************
*** Corporate Carbon Damages relative to Operating Income					****
********************************************************************************	

* Data: Global Sample
cd "`directory'\Data"
use Global_Sample, clear

* Corporate Carbon Damages relative to Operating Income
	
	* Keep only firms with positive operating income
	keep if oper_inc > 0 
	
	* Loop over emission and price series
	local emission = "scope1"
	local price = "51 190 250"
		
	foreach e of local emission {
		
		foreach p of local price {
		
		* Preserve
		preserve
	
			* Display
			di "`e'"
			di "`p'"
	
			* Calculate Damages relative to Operating Income
			** Operating Income is in $M
			gen `e'_damage = [(`e' * `p')/1000000]/oper_inc
								
			* Ratio Truncation
			local var = "`e'_damage"
			
			foreach v of local var { 
				
				* Percentiles
				sum `v', d
				egen `v'_p1 = pctile(`v'), p(1)
				egen `v'_p99 = pctile(`v'), p(99)
										
		}
			
			* Truncation
			drop if `e'_damage < `e'_damage_p1 | `e'_damage > `e'_damage_p99
			
			* Prepare Graphs

				* Price label
				gen price_label = "$`p'"
								
				* Keep only essential variables
				keep entity_id year price_label `e'_damage 
				
				* Rename
				rename `e'_damage damage
				
				* Save
				save `e'_`p', replace
	
		* Restore
		restore
	
		}
	
	}

* Append
use scope1_51, clear
append using scope1_190
append using scope1_250 

* Sort
sort entity_id year damage

* Price label
gen price = 3 if price_label == "$51"
replace price = 2 if price_label == "$190"
replace price = 1 if price_label == "$250"
	
* Keep only essential variables
keep entity_id year price price_label damage
	
* Table S3 Panel A: Descriptive Statistics for Corporate Carbon Damages	
bysort price_label: tabstat damage, stat("count mean sd p10 p25 p50 p75 p90") 

* Figure 1 Panel A: Corporate Carbon Damages relative to Operating Income
			
	* Generate median, quartile, IQR, and mean
	bysort price_label: egen med = median(damage)
	bysort price_label: egen mean = mean(damage)
	bysort price_label: egen ldc = pctile(damage), p(10)
	bysort price_label: egen udc = pctile(damage), p(90)
		
	* Plot Graph
	cd "`directory'\Graphs"
	set scheme s2color
	graph set window fontface "Times New Roman"
	graph twoway rbar udc ldc price, fcolor(gs10) lcolor(none) barw(.15) horizontal || ///
		scatter price med, msymbol(|) msize(*2.5) fcolor(edkblue) mcolor(edkblue) || ///
		scatter price mean, msymbol(|) msize(*2.5) fcolor(dkgreen) mcolor(dkgreen) ///
		legend(off) ///
		xtitle("Carbon Damages scaled by Operating Income", size(medsmall)) xlabel(0 "0" .25 "25%" 0.5 "50%" .75 "75%" 1 "100%" 1.25 "125%", labsize(medsmall) nogrid) ytitle("") ///
		xscale(titlegap(3.5)) ylabel(3 "SCC = $51" 2 "SCC = $190" 1 "SCC = $250", labsize(medsmall) angle(0)) ///
		graphregion(color(white) margin(vlarge)) plotregion(fcolor(white)) 
	graph export fig1a_inc.emf, replace 
	
* Export graph data
		
	* Duplicates drop
	duplicates drop price_label, force
	
	* Keep only essential variables
	keep price_label med mean ldc udc
	
	* Export to excel
	export excel using Appendix.xlsx, sheet("Fig1A_Inc", replace) firstrow(var) 
	
********************************************************************************
*** Corporate Carbon Damages relative to Revenue							****
********************************************************************************	

* Data: Global Sample
cd "`directory'\Data"
use Global_Sample, clear

* Corporate Carbon Damages relative to Revenue 
	
	* Loop over emission and price series
	local emission = "scope1"
	local price = "51 190 250"
		
	foreach e of local emission {
		
		foreach p of local price {
		
		* Preserve
		preserve
	
			* Display
			di "`e'"
			di "`p'"
	
			* Calculate Damages relative to Revenue
			** Revenue is in $M
			gen `e'_damage = [(`e' * `p')/1000000]/tc_rev
								
			* Ratio Truncation
			local var = "`e'_damage"
			
			foreach v of local var { 
				
				* Percentiles
				sum `v', d
				egen `v'_p1 = pctile(`v'), p(1)
				egen `v'_p99 = pctile(`v'), p(99)
										
		}
			
			* Truncation
			drop if `e'_damage <`e'_damage_p1 | `e'_damage >`e'_damage_p99
						
			* Prepare Graphs

				* Price label
				gen price_label = "$`p'"
								
				* Keep only essential variables
				keep entity_id year price_label `e'_damage 
				
				* Rename 
				rename `e'_damage damage
				
				* Save
				cd "`directory'\Data"
				save `e'_`p', replace
	
		* Restore
		restore
	
		}
	
	}

* Append
use scope1_51, clear
append using scope1_190
append using scope1_250 

* Sort
sort entity_id year damage

* Price label
gen price = 3 if price_label == "$51"
replace price = 2 if price_label == "$190"
replace price = 1 if price_label == "$250"
	
* Keep only essential variables
keep entity_id year price price_label damage
	
* Table S3 Panel B: Descriptive Statistics for Corporate Carbon Damages
bysort price_label: tabstat damage, stat("count mean sd p10 p25 p50 p75 p90") 

* Figure 1 Panel A: Corporate Carbon Damages relative to Revenue
			
	* Generate median, quartile, IQR, and mean
	bysort price_label: egen med = median(damage)
	bysort price_label: egen mean = mean(damage)
	bysort price_label: egen ldc = pctile(damage), p(10)
	bysort price_label: egen udc = pctile(damage), p(90)
		
	* Plot Graph
	cd "`directory'\Graphs"
	set scheme s2color
	graph set window fontface "Times New Roman"
	graph twoway rbar udc ldc price, fcolor(gs10) lcolor(none) barw(.15) horizontal || ///
		scatter price med, msymbol(|) msize(*2.5) fcolor(edkblue) mcolor(edkblue) || ///
		scatter price mean, msymbol(|) msize(*2.5) fcolor(dkgreen) mcolor(dkgreen) ///
		legend(off) ///
		xtitle("Carbon Damages scaled by Revenue", size(medsmall)) xlabel(0 "0" .025 "2.5%" 0.05 "5.0%" .075 "7.5%", labsize(medsmall) nogrid) ytitle("") ///
		xscale(titlegap(3.5)) ylabel(3 "SCC = $51" 2 "SCC = $190" 1 "SCC = $250", labsize(medsmall) angle(0)) ///
		graphregion(color(white) margin(vlarge)) plotregion(fcolor(white)) 
	graph export fig1a_rev.emf, replace 

* Export graph data
		
	* Duplicates drop
	duplicates drop price_label, force
	
	* Keep only essential variables
	keep price_label med mean ldc udc
	
	* Export to excel
	export excel using Appendix.xlsx, sheet("Fig1A_Rev", replace) firstrow(var) 	

********************************************************************************
