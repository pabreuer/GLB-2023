********************************************************************************
*** Title: What might disclosure rules reveal about corporate carbon damages? **
*** Date: 07/25/2023														****
*** Author: P. Breuer														****
*** Project: Global Sample - Sample construction							****
********************************************************************************

* Preliminaries
clear all
set more off
set maxvar 15000

* Seed 
set seed 91011

* Directory
local directory = "...\Global_Sample" /* Please insert/adjust directory path */
cd "`directory'\Data"

********************************************************************************
*** Sample Description: Global Public Firm Sample							****
********************************************************************************	

/* To construct the global sample of public firms, we start with the ESG Coverage List from the S&P CIQ Pro Platform as of 01/11/2022.  
We do not apply any of the available filters within the platform, i.e., we include all sectors, data sets, company types, and geographies resulting in a sample of 23,441 firms. 
We use S&P's company type classification (Key Field: 322992) to identify firms that are publicly traded. 
As this field is static, it indicates whether firms were publicly traded as of the date of our download. 
We drop 6,839 firms that are privately owned and 26 because they have an invalid company ID. 
We lose 1,395 public firms with missing information on their carbon emissions. 
In total, we have 15,181 publicly-traded firm observations with non-missing reported or estimated Scope 1 emissions in 2019. 
None of these firms have missing revenue information. 
Information on operating income is missing for 63 observations. 
12,969 firms have positive operating income. */

********************************************************************************
*** Import Static Variables from S&P CIQ Pro for Firms in the ESG Coverage List
********************************************************************************	

* Data: S&P Static Variables for ESG Coverage List
** Download date: January 11, 2022
** All static information (i.e., company type, identifiers, industry, and country) is as of the download date, e.g., firms with company type "Public Company" were public as of January 11, 2022

* Data: S&P Legal Company Information
	
	* Data
	import excel using Static_Variables_01-11-2022.xlsx, sheet("CIQ_STATIC") cellrange(A3) firstrow case(lower) clear

	* Drop empty row
	drop if a == ""

	* Rename
	rename a entity_name
	label var entity_name "Company Name"
	rename b entity_id 
	label var entity_id "S&P Identifier"
	rename sp_company_type company_type
	label var company_type "Type of universal entity"
	rename sp_isin isin
	label var isin "ISIN"
	rename sp_lei lei
	label var lei "Legal Entity Identifier"
	rename iq_sector sector
	label var sector "S&P IQ Sector"
	rename iq_industry_group industry_group
	label var industry_group "S&P IQ Industry Group"
	rename iq_industry industry
	label var industry "S&P IQ Industry"
	rename tc_industry_classification_secto tc_industry
	label var tc_industry "Trucost Business Activity"
	rename sp_country_name country_name
	label var country_name "Country"
	rename sp_country_code ctrycd
	label var ctrycd "Country Code"
	
	* Keep essential variables only
	keep entity_* company_type isin lei country_name ctrycd sector industry_group industry tc_industry
	
	* Save
	save Static_Variables, replace
	
********************************************************************************
*** Import Time-Series Variables from S&P CIQ Pro for Firms in the ESG Coverage List
********************************************************************************	

* Data: S&P Time-Series Variables for ESG Coverage List
** Download date: January 11, 2022
** Download years: 2004 - 2020

* Data: Trucost GHG emissions and revenue 

	* Data
	import excel using Time_Series_Variables_01-11-2022.xlsx, sheet("CY") cellrange(A3) firstrow case(lower) clear
	
	* Rename
	rename a entity_name
	label var entity_name "Company Name"
	rename b entity_id 
	label var entity_id "S&P Identifier"
	rename c tc_id
	label var tc_id "TC Identifier"
	rename d year
	label var year "Year"
	rename tc_absolute_ghg_scope_1 scope1
	label var scope1 "GHG Scope 1 emissions"
	rename tc_absolute_ghg_scope_2 scope2
	label var scope2 "GHG Scope 2 emissions"
	rename tc_absolute_ghg_scope_3_downstre scope3down
	label var scope3down "GHG scope 3 downstream emissions"
	rename tc_absolute_ghg_scope_3 scope3up
	label var scope3up "GHG scope 3 upstream emissions"
	rename tc_absolute_ghg_direct direct_scope
	label var direct_scope "GHG Direct emissions"
	rename tc_absolute_ghg_1st_tier_indirec indirect_scope
	label var indirect_scope "GHG 1st Tier Indirect emissions"
	rename tc_absolute_ghg_direct_and_1st_t total_scope
	label var total_scope "GHG Direct and 1st Tier Indirect emissions"
	rename tc_company_rev tc_rev
	label var tc_rev "Trucost Revenue"

	* Drop unnecessary variables
	drop e f

	* Destring numeric variables
	destring scope1 scope2 scope3down scope3up direct_scope indirect_scope total_scope tc_rev, replace ignore("# INVALID COMPANY")
	
	* Save
	save Time-Series_GHG, replace
	
* Data: S&P CIQ Financial information 

	* Data
	import excel using Time_Series_Variables_01-11-2022.xlsx, sheet("FY") cellrange(A3) firstrow case(lower) clear
	
	* Rename
	rename a entity_name
	label var entity_name "Company Name"
	rename b entity_id 
	label var entity_id "S&P Identifier"
	rename c tc_id
	label var tc_id "TC Identifier"
	rename d year
	label var year "Year"
	rename iq_oper_inc oper_inc
	label var oper_inc "Operating Income"

	* Keep essential variables only
	keep entity_* tc_id year oper_inc

	* Destring numeric variables
	destring oper_inc, replace ignore("# INVALID COMPANY")
	
	* Save
	save Time-Series_Financial, replace

* Loop over Excel sheets
** Scope1_Flag: Trucost Emission Disclosure Flags for Scope 1
** Scope2_Flag: Trucost Emission Disclosure Flags for Scope 2
local scope = "SCOPE1_FLAG SCOPE2_FLAG"

foreach s of local scope {
	
	* Display
	di "`s'"
	
	* Data: Trucost Disclosure Flags
	import excel using Time_Series_Variables_01-11-2022.xlsx, sheet(`s') cellrange(A4) firstrow case(lower) clear

	* Rename
	rename a entity_name
	label var entity_name "S&P Name of Entity"
	rename b entity_id 
	label var entity_id "S&P Identifier"
		
	* Reshape
	reshape long cy, i(entity_id) j(year)
	label var year "Year"
	rename cy `s'
	rename `s', lower

	* Save
	save Time-Series_`s', replace

}	

********************************************************************************	
*** Combine Static and Time-Series Datasets 								**** 				
********************************************************************************

* Data
use Static_Variables, clear

* Merge
merge 1:m entity_id using Time-Series_GHG
drop _merge

* Loop over datasets
local dataset = "Financial SCOPE1_FLAG SCOPE2_FLAG"

foreach d of local dataset {
	
	* Merge
	merge 1:1 entity_id year using Time-Series_`d'
	drop _merge

	}

* Keep sample year
keep if year == 2019	

* Intermediate Save
save ESG_Sample, replace

* Keep public companies only
keep if company_type == "Public Company"

* Keep if scope information is non-missing
keep if scope1 !=. & scope2 !=.

* Order
order entity_name entity_id tc_id year 

* Save
save Global_Sample, replace
	
********************************************************************************
