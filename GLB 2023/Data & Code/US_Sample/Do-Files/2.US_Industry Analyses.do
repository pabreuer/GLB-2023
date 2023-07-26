********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: U.S. Sample - Industry Level Analyses							****
********************************************************************************

* Preliminaries 
clear all
set more off
set maxvar 15000

* Seed
set seed 91011

* Directory 
local directory = "...\US_Sample" /* Please insert/adjust directory path */

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

* Data: U.S. Sample
cd "`directory'\Data"
use US_Sample, clear

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
								
			* Table S5 Panel B: Descriptive Statistics for Corporate Carbon Damages by Industry 
			* Table S6 Panel B: Corporate Carbon Damages by Industry and SCC Estimate
			bysort industries: tabstat damage, stat("count mean sd p10 p25 p50 p75 p90") 
			tabstat damage, stat("mean")			
			
			* Figure 2 Panel B: Corporate Carbon Damages by Industry
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
					text(1 1.5 " 139%", place(e) size(.175cm)) ///
					text(2 1.5 " 87%", place(e) size(.175cm)) ///
					text(3 .0556941 " 2%", place(e) size(.175cm)) ///
					text(4 .1347832 " 5%", place(e) size(.175cm)) ///
					text(5 .0272038 " 3%", place(e) size(.175cm)) ///
					text(6 .1463459 " 6%", place(e) size(.175cm)) ///
					text(7 .1322555 " 5%", place(e) size(.175cm)) ///
					text(8 .0360539 " 2%", place(e) size(.175cm)) ///
					text(9 .0380945 " 2%", place(e) size(.175cm)) ///
					text(10 .0171351 " <1%", place(e) size(.175cm)) ///
					text(11 1.5 " 68%", place(e) size(.175cm)) ///
					text(12 .0016154 " <1%", place(e) size(.175cm)) ///
					text(13 .1928496 " 6%", place(e) size(.175cm)) ///
					text(14 .0725474 " 6%", place(e) size(.175cm)) ///
					text(15 .2325959 " 25%", place(e) size(.175cm)) ///
					text(16 .6008236 " 34%", place(e) size(.175cm)) ///
					text(17 1.5 " 81%", place(e) size(.175cm)) ///
					text(18 .0131873 " <1%", place(e) size(.175cm)) ///
					text(19 .1807607 " 9%", place(e) size(.175cm)) ///
					text(20 .212842 " 11%", place(e) size(.175cm)) ///
					text(21 .2640194 " 10%", place(e) size(.175cm)) ///
					text(22 .1596577 " 8%", place(e) size(.175cm)) ///
					text(23 .0007901 " <1%", place(e) size(.175cm)) ///
					text(24 .3722447 " 11%", place(e) size(.175cm)) ///
					legend(off) xline(`r(mean)', lpat(shortdash) lcolor(edkblue)) xline(1.509, lpat(solid) lcolor(bluishgray) lwidth(thick)) ///
					xtitle("Carbon Damages", size(vsmall)) xlabel(0 "0" 0.5 "50%" 1 "100%" 1.5 "150%", labsize(vsmall) nogrid) ytitle("") ///
					ylabel(24 "Automobiles and Components (N=23)" 23 "Banks (N=117)" 22 "Capital Goods (N=139)" ///
					21 "Commercial and Professional Services (N=47)" ///
					20 "Consumer Durables and Apparel (N=56)" 19 "Consumer Services (N=54)" 18 "Diversified Financials (N=45)" 17 "Energy (N=48)" ///
					16 "Food and Staples Retailing (N=14)" 15 "Food, Beverage and Tobacco (N=42)" 14 "Health Care Equipment and Services (N=97)" ///
					13 "Household and Personal Products (N=15)" 12 "Insurance (N=50)" 11 "Materials (N=79)" 10 "Media and Entertainment (N=35)" ///
					9 "Pharmaceuticals, Biotechnology and Life Sciences (N=52)" 8 "Real Estate (N=111)" 7 "Retailing (N=69)" ///
					6 "Semiconductors and Semiconductor Equipment (N=40)" ///
					5 "Software and Services (N=68)" 4 "Technology Hardware and Equipment (N=57)" 3 "Telecommunication Services (N=9)" ///
					2 "Transportation (N=33)" ///
					1 "Utilities (N=44)", ///
					labsize(vsmall) angle(0)) ///
					graphregion(color(white)) plotregion(fcolor(white)) 
				graph export fig2b.emf, replace 
					
			* Export graph data
		
				* Duplicates drop
				duplicates drop industries, force
				
				* Keep only essential variables
				keep industry_group count med mean ldc udc udc_trunc sample_avg
				
				* Export to excel
				export excel industry_group count med mean ldc udc udc_trunc sample_avg using Appendix.xlsx, sheet("Fig2B_Inc", replace) firstrow(var) 
		
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
	