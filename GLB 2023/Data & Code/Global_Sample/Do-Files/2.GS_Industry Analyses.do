********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: Global Sample - Industry Level Analyses						****
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
*** Corporate Carbon Damages by Industry									****
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
			** Operating Income in $M
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
			drop if `e'_damage <`e'_damage_p1 | `e'_damage >`e'_damage_p99
			
			* Prepare Graphs
			
				* Industry label
				gen industries = 24 if industry_group == "Automobiles and Components"
				replace industries = 23 if industry_group == "Banks"
				replace industries = 22 if industry_group == "Capital Goods"
				replace industries = 21 if industry_group == "Commercial and Professional Services"
				replace industries = 20 if industry_group == "Consumer Durables and Apparel"
				replace industries = 19 if industry_group == "Consumer Services"
				replace industries = 18 if industry_group == "Diversified Financials"
				replace industries = 17 if industry_group == "Energy"
				replace industries = 16 if industry_group == "Food and Staples Retailing"
				replace industries = 15 if industry_group == "Food, Beverage and Tobacco"
				replace industries = 14 if industry_group == "Health Care Equipment and Services"
				replace industries = 13 if industry_group == "Household and Personal Products"
				replace industries = 12 if industry_group == "Insurance"
				replace industries = 11 if industry_group == "Materials"
				replace industries = 10 if industry_group == "Media and Entertainment"
				replace industries = 9 if industry_group == "Pharmaceuticals, Biotechnology and Life Sciences"
				replace industries = 8 if industry_group == "Real Estate"
				replace industries = 7 if industry_group == "Retailing"
				replace industries = 6 if industry_group == "Semiconductors and Semiconductor Equipment"
				replace industries = 5 if industry_group == "Software and Services"
				replace industries = 4 if industry_group == "Technology Hardware and Equipment"
				replace industries = 3 if industry_group == "Telecommunication Services"
				replace industries = 2 if industry_group == "Transportation"
				replace industries = 1 if industry_group == "Utilities"
				
				* Keep only essential variables
				keep industry_group industries `e'_damage oper_inc
				
				* Rename
				rename `e'_damage damage
								
			* Table S5 Panel A: Descriptive Statistics for Corporate Carbon Damages by Industry 
			* Table S6 Panel A: Corporate Carbon Damages by Industry and SCC Estimate
			bysort industries: tabstat damage, stat("count mean sd p10 p25 p50 p75 p90") 
			tabstat damage, stat("mean")			
			
			* Figure 2 Panel A: Corporate Carbon Damages by Industry
			** SCC = 190
			if `p' == 190 {
			
				* Generate median, quartile, IQR, and mean
				bysort industries: egen med = median(damage)
				bysort industries: egen mean = mean(damage)
				bysort industries: egen ldc = pctile(damage), p(10)
				bysort industries: egen udc = pctile(damage), p(90)
				bysort industries: gen count = _N
				
				* For industries with udc > 1.5 set to 1.5
				gen udc_trunc = udc
				replace udc_trunc = 1.5 if udc > 1.5
								
				* Plot Graph
				cd "`directory'\Graphs"
				set scheme s2color
				graph set window fontface "Times New Roman"
				sum damage, d
				egen sample_avg = mean(damage)
				graph twoway rbar udc_trunc ldc industries, fcolor(gs10) lcolor(none) barw(.5) horizontal || ///
					scatter industries med, msymbol(|) msize(*.9) fcolor(edkblue) mcolor(edkblue) ///
					text(1 1.5 " 205%", place(e) size(.175cm)) ///
					text(2 1.5 " 115%", place(e) size(.175cm)) ///
					text(3 .041515 " 7%", place(e) size(.175cm)) ///
					text(4 .3215834 " 17%", place(e) size(.175cm)) ///
					text(5 .0439642 " 3%", place(e) size(.175cm)) ///
					text(6 .3232334 " 20%", place(e) size(.175cm)) ///
					text(7 .1847299 " 10%", place(e) size(.175cm)) ///
					text(8 .0355186 " 3%", place(e) size(.175cm)) ///
					text(9 .11358 " 8%", place(e) size(.175cm)) ///
					text(10 .0314566 " 2%", place(e) size(.175cm)) ///
					text(11 1.5 " 173%", place(e) size(.175cm)) ///
					text(12 .0037466 " <1%", place(e) size(.175cm)) ///
					text(13 .3942049 " 21%", place(e) size(.175cm)) ///
					text(14 .1483458 " 13%", place(e) size(.175cm)) ///
					text(15 1.5 " 62%", place(e) size(.175cm)) ///
					text(16 .4152656 " 20%", place(e) size(.175cm)) ///
					text(17 1.5 " 135%", place(e) size(.175cm)) ///
					text(18 .0065847 " 2%", place(e) size(.175cm)) ///
					text(19 .1798217 " 14%", place(e) size(.175cm)) ///
					text(20 .4510404 " 23%", place(e) size(.175cm)) ///
					text(21 .3774253 " 21%", place(e) size(.175cm)) ///
					text(22 .3692889 " 19%", place(e) size(.175cm)) ///
					text(23 .0018063 " <1%", place(e) size(.175cm)) ///
					text(24 .3264244 " 25%", place(e) size(.175cm)) ///
					legend(off) xline(`r(mean)', lpat(shortdash) lcolor(edkblue)) xline(1.509, lpat(solid) lcolor(bluishgray) lwidth(thick)) ///
					xtitle("Carbon Damages", size(vsmall)) xlabel(0 "0" 0.5 "50%" 1 "100%" 1.5 "150%", labsize(vsmall) nogrid) ytitle("") ///
					ylabel(24 "Automobiles and Components (N=336)" 23 "Banks (N=734)" 22 "Capital Goods (N=1,669)" ///
					21 "Commercial and Professional Services (N=358)" ///
					20 "Consumer Durables and Apparel (N=529)" 19 "Consumer Services (N=437)" 18 "Diversified Financials (N=436)" 17 "Energy (N=447)" ///
					16 "Food and Staples Retailing (N=187)" 15 "Food, Beverage and Tobacco (N=578)" 14 "Health Care Equipment and Services (N=433)" ///
					13 "Household and Personal Products (N=122)" 12 "Insurance (N=237)" 11 "Materials (N=1,271)" 10 "Media and Entertainment (N=436)" ///
					9 "Pharmaceuticals, Biotechnology and Life Sciences (N=451)" 8 "Real Estate (N=998)" 7 "Retailing (N=457)" ///
					6 "Semiconductors and Semiconductor Equipment (N=331)" ///
					5 "Software and Services (N=558)" 4 "Technology Hardware and Equipment (N=733)" 3 "Telecommunication Services (N=161)" ///
					2 "Transportation (N=412)" ///
					1 "Utilities (N=400)", ///
					labsize(vsmall) angle(0)) ///
					graphregion(color(white)) plotregion(fcolor(white)) 
				graph export fig2a.emf, replace 
									
			* Export graph data
		
				* Duplicates drop
				duplicates drop industries, force
				
				* Keep only essential variables
				keep industry_group count med mean ldc udc udc_trunc sample_avg 
				
				* Export to excel
				export excel industry_group count med mean ldc udc udc_trunc sample_avg using Appendix.xlsx, sheet("Fig2A_Inc", replace) firstrow(var) 
						
		* Restore
		restore
		
			}
		
		else {
		
		* Restore
		restore
			
			}
			
		}
	
	}	

********************************************************************************	
	