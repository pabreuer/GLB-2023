********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: U.S. Sample - Sample construction								****
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
*** Sample Description: U.S. S&P 1500 Sample								****
********************************************************************************	

/* We obtain the S&P 1500 Constituent List from the S&P CIQ Pro database as of 12/16/2021. 
The list covers 1,499 firms, of which 1,447 firms have non-missing information on reported or estimated Scope 1 emissions in 2019. 
None of these firms have missing revenue information. 
Information on operating income is missing for 2 observations. 
1,370 firms have positive operating income. */

********************************************************************************
*** Import and Merge S&P 1500 list from S&P CIQ Pro							****
********************************************************************************

* Data: S&P 1500 list 
** Download: December 16, 2021
** 1,499 firms

	* Data
	cd "`directory'\Data"
	import excel using sp1500_12-16-2021.xlsx, cellrange(A3) clear
	
	* Rename
	rename A entity_name
	label var entity_name "Company Name"
	rename B entity_id 
	label var entity_id "S&P Identifier"

	* Merge with ESG Sample
	cd "...\Global_Sample\Data" /* Please insert/adjust directory path */
	merge 1:1 entity_id using ESG_Sample
	drop if _merge !=3
	drop _merge

	* Keep if scope information is non-missing
	keep if scope1 !=. & scope2 !=.

	* Save
	cd "`directory'\Data"
	save US_Sample, replace

********************************************************************************
