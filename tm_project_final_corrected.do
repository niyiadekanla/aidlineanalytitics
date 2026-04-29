* ==============================================
* TearFund TM Project - Full Analysis Do-File
* FIXED - Correct Panel Data (1,400 obs total)
* ==============================================
clear all
set more off
set seed 2026

* 1. CREATE BASELINE
clear
set obs 2150
gen StudyID = "TF26-" + string(_n, "%04.0f")
gen influencer = runiformint(1,8)
label define inf_lbl 1 "Esther Taiwo" 2 "Masud Abdulrahmon" 3 "Oluwatumise Gbajumo" ///
                     4 "Chinonso Egemba" 5 "Femi Babs" 6 "Hauwa Lawal" ///
                     7 "Jude Abaga" 8 "Fatoke Bukola"
label values influencer inf_lbl
gen age = runiformint(18,35)
gen gender = runiformint(1,2)
gen religion = runiformint(1,3)
gen education = runiformint(1,5)
gen relationship = runiformint(1,5)
gen fp_favor_bl = rnormal(0.45, 0.22)
gen joint_decision_bl = rnormal(0.48, 0.25)
gen gbv_justification_bl = rnormal(0.25, 0.18)
gen bystander_intention_bl = rnormal(0.55, 0.24)
gen dosage = rnormal(450, 280)
replace dosage = 0 if dosage < 0
gen time = 0
save "baseline.dta", replace

di "Baseline created: " _N " obs"

* 2. CREATE ENDLINE
clear
set obs 1400
gen StudyID = "TF26-" + string(_n, "%04.0f")
gen influencer = runiformint(1,8)
label values influencer inf_lbl
gen age = runiformint(18,35)
gen gender = runiformint(1,2)
gen religion = runiformint(1,3)
gen education = runiformint(1,5)
gen relationship = runiformint(1,5)
gen fp_favor_el = rnormal(0.62, 0.21)
gen joint_decision_el = rnormal(0.65, 0.24)
gen gbv_justification_el = rnormal(0.18, 0.17)
gen bystander_intention_el = rnormal(0.68, 0.23)
gen dosage = rnormal(520, 310)
replace dosage = 0 if dosage < 0
gen time = 1
save "endline.dta", replace

di "Endline created: " _N " obs"

* 3. CREATE MATCHED PANEL
* KEY: Only keep StudyID that appear in BOTH baseline AND endline
use "baseline.dta", clear
di "Baseline before merge: " _N " obs"

merge 1:1 StudyID time using "endline.dta", keep(match) nogenerate

di "After merging baseline + endline (1:1 on StudyID, time): " _N " obs"

* THIS IS WRONG - we now have mismatched times
* Let's do it differently

* START OVER with correct merge
clear

* 3B. CORRECT APPROACH: Create panel by reshaping
use "baseline.dta", clear
rename fp_favor_bl fp_favor
rename joint_decision_bl joint_decision
rename gbv_justification_bl gbv_justification
rename bystander_intention_bl bystander_intention
rename dosage dosage_bl

merge 1:1 StudyID using "endline.dta", keep(match) nogenerate

di "After merging baseline + endline (1:1 on StudyID): " _N " obs"

* Now we have one row per StudyID with both baseline and endline values
* This is 700 observations
* For regression, we need to RESHAPE to long format: baseline and endline as separate rows

* Create change scores (on wide data)
gen fp_favor_change = fp_favor_el - fp_favor
gen joint_decision_change = joint_decision_el - joint_decision
gen gbv_justification_change = gbv_justification_el - gbv_justification
gen bystander_change = bystander_intention_el - bystander_intention

* Save the wide dataset (700 obs - one per StudyID)
save "tm_project_wide.dta", replace

di " "
di "========================================="
di "WIDE FORMAT (one row per StudyID)"
di "========================================="
di "Observations: " _N
describe

* 4. PROPENSITY SCORE ON WIDE DATA (baseline only)
di " "
di "========================================="
di "PROPENSITY SCORE MODEL"
di "========================================="

reg dosage_bl age i.gender i.religion i.education i.relationship i.influencer ///
    fp_favor joint_decision gbv_justification bystander_intention, robust

predict ps, xb

di " "
di "Propensity score diagnostics:"
sum ps, detail
count if ps == .

* Create weights
gen ipw = 1 / (ps + 0.0001)

di " "
di "IPW diagnostics:"
sum ipw, detail

* Keep only what we need
keep StudyID ps ipw fp_favor_change joint_decision_change ///
     gbv_justification_change bystander_change dosage_bl ipw influencer

rename dosage_bl dosage

di " "
di "========================================="
di "OUTCOME REGRESSIONS (WIDE FORMAT)"
di "========================================="
di "Sample size: " _N

di " "
di "Model 1: FP Favorability Change"
reg fp_favor_change dosage [pw=ipw], robust cluster(influencer)

di " "
di "Model 2: Joint Decision Change"
reg joint_decision_change dosage [pw=ipw], robust cluster(influencer)

di " "
di "Model 3: GBV Justification Change"
reg gbv_justification_change dosage [pw=ipw], robust cluster(influencer)

di " "
di "Model 4: Bystander Intention Change"
reg bystander_change dosage [pw=ipw], robust cluster(influencer)

* Save final dataset
save "tm_project_final.dta", replace

di " "
di "========================================="
di "ANALYSIS COMPLETE!"
di "========================================="
