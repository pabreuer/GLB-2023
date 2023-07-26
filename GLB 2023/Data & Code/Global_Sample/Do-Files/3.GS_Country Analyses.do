********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: Global Sample - Country Level Analyses							****
********************************************************************************

* Preliminaries ****
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
***	Corporate Carbon Damages by Country										****
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
			
			* Major Economies Forum (MEF)
			replace country = "European Union (Rest)" if country == "Austria" | country == "Belgium" | country == "Bulgaria" | country == "Croatia" | country == "Cyprus" | country == "Czechia" | country == "Denmark" | country == "Estonia" | country == "Finland" | country == "Greece" | country == "Hungary" | country == "Ireland" | country == "Latvia" | country == "Lithuania" | country == "Luxembourg" | country == "Malta" | country == "Netherlands" | country == "Poland" | country == "Portugal" | country == "Romania" | country == "Slovakia" | country == "Slovenia" | country == "Spain" | country == "Sweden"
			keep if country == "Australia" | country == "Brazil" | country == "Canada" | country == "China" | ///
				country == "European Union (Rest)" | country == "France" | country == "Germany" | country == "India" | ///
				country == "Indonesia" | country == "Italy" | country == "Japan" | country == "South Korea" | ///
				country == "Mexico" | country == "Russia" | country == "South Africa" | country == "United Kingdom" | /// 
				country == "USA" 	
			
			* Keep only essential variables
			keep country industry_group `e'_damage 
				
			* Rename
			rename `e'_damage damage
			
			* Table 1 Column 1 & 2a: Corporate Carbon Damages by Country 
			* Table S7: Descriptive Statistics for Corporate Carbon Damages by Country
			* Table S8: Corporate Carbon Damages by Country and SCC Estimate
			bysort country: tabstat damage, stat("count mean sd p10 p25 p50 p75 p90")
			tabstat damage, stat("mean")
			bysort country: egen mean = mean(damage)
			
			* Industry-adjusted Corporate Carbon Damages
			
				* Industry fixed effects
				encode industry_group, gen(gics)				

				* Log regression
				gen ln_damage = ln(damage)
				reg ln_damage ibn.gics, noconstant
				predict ln_residuals, residuals

				* Table 1 Column 3: Corporate Carbon Damages by Country
				bysort country: tabstat ln_residuals, stat("count mean sd p10 p25 p50 p75 p90")
				bysort country: egen mean_residuals = mean(ln_residuals)
				
			* Rankings
			
				* Duplicates drop
				duplicates drop country, force
			
				* Unadjusted ranking 
				gsort -mean 
				gen unadj_ranking = _n
				bysort country: tab unadj_ranking
				
				* Industry-adjusted ranking 
				gsort -mean_residuals 
				gen adj_ranking = _n
				bysort country: tab adj_ranking 
								
		* Restore
		restore
				
		}	
				
	}
	
********************************************************************************
