

use "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"

****************

generate StartDate = date(start_date, "YMD") //Patient Start Date
format StartDate %tdDD/NN/CCYY


generate EndDate = date(end_date, "YMD") //Patient End Date
format EndDate %tdDD/NN/CCYY
 
generate IndexDate = date(index_date, "YMD") //IndexDate (Date when a patient enters study)
format IndexDate %tdDD/NN/CCYY


generate YearofBirth = date(year_of_birth, "YMD") //DateOfBirth (Accurate to month level for children & accurate to year level for adults)
format YearofBirth %tdDD/NN/CCYY


generate TransferDate = date(transfer_date, "YMD") //Patient transfer date out of practice
format TransferDate %tdDD/NN/CCYY

generate DeathDate = date(death_date, "YMD") 									
format DeathDate %tdDD/NN/CCYY				

generate CollectionDate = date(collection_date, "YMD") //Data when the last set of medical records were collected from the practice to THIN
format CollectionDate %tdDD/NN/CCYY
			

generate RegistrationDate = date(registration_date, "YMD") //Patient registration date to practice
format RegistrationDate %tdDD/NN/CCYY
***************


*******************

****Some ways to validate the temporality of the dataset
count if CollectionDate-IndexDate < 0 //check collection date is after index date
count if DeathDate-IndexDate < 0 //check death date is after index date
count if TransferDate-IndexDate < 0 //check transfer date is after index date
count if IndexDate-RegistrationDate < 0 //check index date is after registration date
***********************


***** Set Index Date to 1.1.2015*****
drop if IndexDate >td(01/01/2015)

*****relabel sex
gen Sex = 1 if sex == "M"
replace Sex = 2 if sex == "F"
label define sexLab 1 "Male" 2 "Female"
label value Sex sexLab
tab Sex
drop sex

**age
gen long age = (IndexDate - YearofBirth)/ 365.25
sum age, detail
recode age (min/15.9=1 "<16 years")(18/29.9=2 "18 - 30 years") (30/39.9=3 "30 - 40 years") (40/49.9=4 "40 - 50 years") (50/59.9=5 "50 - 60 years") (60/69.9=6 "60 - 70 years") (70/max=7 ">70 years"), gen (agecat)
label var agecat "age categories (grouped)"
tab agecat
***************
**Keep only those with Sex explicitly defined as Male or Female and Age over 18 
drop if Sex==.

drop if age_at_index < 18 

****IMD score categories********

gen temp_IMD = 1 if e2019_imd_5 == 1
replace temp_IMD = 2 if e2019_imd_5 == 2
replace temp_IMD = 3 if e2019_imd_5 == 3
replace temp_IMD = 4 if e2019_imd_5 == 4
replace temp_IMD = 5 if e2019_imd_5 == 5
replace temp_IMD = 6 if  e2019_imd_5 == . | e2019_imd_5 == 0
recode temp_IMD (1 = 1 "1(LeastDeprived)")(2 = 2 "2")(3 = 3 "3")(4 = 4 "4")(5 = 5 "5(MostDeprived)")(6 = 6 "Missing") , gen(IMDeprivation)
tab IMDeprivation e2019_imd_5, mis
drop temp_IMD
tab IMDeprivation



******relabel ethnicity
gen Ethnicity = 1 if ethnicity == "WHITE"
replace Ethnicity = 2 if ethnicity == "BLACK"
replace Ethnicity = 3 if ethnicity == "ASIAN"
replace Ethnicity = 4 if ethnicity == "MIXED"
replace Ethnicity = 5 if ethnicity == "OTHER"
replace Ethnicity = 6 if ethnicity == "MISSING"
label define ethnicLab 1 "White" 2 "Black" 3 "Asian" 4 "Mixed_Race" 5 "Others" 6 "Missing"
label value Ethnicity ethnicLab
tab Ethnicity
drop ethnicity



gen ED_death= min(DeathDate, EndDate , TransferDate, td(01/01/2020)) 
format ED_death %tdDD/NN/CCYY 
gen PY_death = (ED_death - IndexDate)/365.25 
replace PY_death= 0.0001 if PY_death == 0


** Cox regression 

stset PY_death, failure(death==1)

**** check demographics 
stcox i.agecat i.Sex i.IMDeprivation i.Ethnicity
****************************************************************************************************************************************************************************************************************************


****************************************************************************************
*************SORT DATES *******************************


**** Only count conditions diagnosed before Index date 01.01.2015


****Diabetes ****

gen T2DiabetesDate =date(bd_meditype2diabetes_11_3_21_bir, "YMD")
format T2DiabetesDate  %tdDD/NN/CCYY
replace T2DiabetesDate =. if T2DiabetesDate >td(01/01/2015)

gen T2Diabetes =0 
replace T2Diabetes =1 if T2DiabetesDate !=.
tab T2Diabetes
***
gen T1DiabetesDate =date(bd_meditype1dm_11_3_21_birm_cam2 , "YMD")
format T1DiabetesDate  %tdDD/NN/CCYY
replace T1DiabetesDate =. if T1DiabetesDate >td(01/01/2015)

gen T1Diabetes =0 
replace T1Diabetes =1 if T1DiabetesDate !=.
tab T1Diabetes
****
gen RetinopathyDate =date(bd_medidiabetic_retinopathy_birm  , "YMD")
format RetinopathyDate  %tdDD/NN/CCYY
replace RetinopathyDate  =. if RetinopathyDate  >td(01/01/2015)

gen Retinopathy=0 
replace Retinopathy =1 if RetinopathyDate !=.
tab Retinopathy
****
gen STRDate =date( bd_medisightthreateningretinopat , "YMD")
format STRDate  %tdDD/NN/CCYY
replace STRDate  =. if STRDate  >td(01/01/2015)

gen STR=0 
replace STR =1 if STRDate !=.
tab STR

****
gen FootUlcerDate =date( bd_medidiabetesfootulcer_zhaonan  , "YMD")
format FootUlcerDate  %tdDD/NN/CCYY
replace FootUlcerDate  =. if FootUlcerDate  >td(01/01/2015)

gen FootUlcer=0 
replace FootUlcer =1 if FootUlcerDate !=.
tab FootUlcer

tab2 T1Diabetes FootUlcer, row
tab2 T2Diabetes FootUlcer, row
 ****
 
 gen CharcotFootDate =date( bd_medicharcot_foot_cprdaurum14  , "YMD")
format CharcotFootDate  %tdDD/NN/CCYY
replace CharcotFootDate  =. if CharcotFootDate  >td(01/01/2015)

gen CharcotFoot=0 
replace CharcotFoot =1 if CharcotFootDate !=.
tab CharcotFoot

tab2 T2Diabetes CharcotFoot, row mis 
 
 ****
  gen LowFootScoreDate =date( bd_medifootscorelowrisk_zhaonan1   , "YMD")
format LowFootScoreDate  %tdDD/NN/CCYY
replace LowFootScoreDate  =. if LowFootScoreDate  >td(01/01/2015)

gen LowFootScore=0 
replace LowFootScore =1 if LowFootScoreDate !=.
tab LowFootScore

tab2 T2Diabetes LowFootScore, row mis 
 
 ***
   gen MedFootScoreDate =date( bd_medifootscoremediumrisk_zhaon  , "YMD")
format MedFootScoreDate  %tdDD/NN/CCYY
replace MedFootScoreDate  =. if MedFootScoreDate  >td(01/01/2015)

gen MedFootScore=0 
replace MedFootScore =1 if MedFootScoreDate !=.
tab MedFootScore

tab2 T2Diabetes MedFootScore, row mis 
*****
gen HighFootScoreDate =date( bd_medifootscorehighrisk_zhaonan   , "YMD")
format HighFootScoreDate  %tdDD/NN/CCYY
replace HighFootScoreDate  =. if HighFootScoreDate  >td(01/01/2015)

gen HighFootScore=0 
replace HighFootScore =1 if HighFootScoreDate !=.
tab HighFootScore

tab2 T2Diabetes HighFootScore, row mis 
*****
 gen UnspecFootScoreDate =date( bd_medifootscorenonspecifiedrisk , "YMD")
format UnspecFootScoreDate  %tdDD/NN/CCYY
replace UnspecFootScoreDate  =. if UnspecFootScoreDate  >td(01/01/2015)

gen FootatRiskScore=0 
replace FootatRiskScore =1 if UnspecFootScoreDate !=.
tab FootatRiskScore

tab2 T2Diabetes FootatRiskScore, row mis 
 
******   
  gen AmputationDate =date( bd_mediamputation_diabeticfoot19  , "YMD")
format AmputationDate  %tdDD/NN/CCYY
replace AmputationDate  =. if AmputationDate  >td(01/01/2015)

gen DiabFootAmp=0 
replace DiabFootAmp =1 if AmputationDate !=.
tab DiabFootAmp


******Gangrene Foot

gen GangreneFootDate =date( bd_medigangrene_zhaonan30 , "YMD")
format GangreneFootDate  %tdDD/NN/CCYY
replace GangreneFootDate  =. if GangreneFootDate  >td(01/01/2015)

gen GangreneFoot=0 
replace GangreneFoot =1 if GangreneFootDate !=.
tab GangreneFoot


 ***** increased specificity for Type 1 DM - include only those with no code for Type 2 DM
 
   

 replace T1Diabetes=0 if T2Diabetes==1
 tab T1Diabetes
 
 
 **** Generate diabetic foot categories ******

gen DiabFoot =0 
replace DiabFoot =1 if LowFootScore ==1
replace DiabFoot =2 if MedFootScore ==1
replace DiabFoot =3 if HighFootScore ==1
replace DiabFoot =4 if DiabFootAmp ==1 | FootUlcer ==1 |CharcotFoot ==1 | GangreneFoot==1
 
label define DiabFootLab 0 "No score" 1 "Foot ulcer risk score LOW" 2 "Foot ulcer risk score MEDIUM" 3 "Foot ulcer risk score HIGH"  4 "Active foot problem"
label value DiabFoot DiabFootLab 
tab DiabFoot
  
  
tab DiabFoot if T2Diabetes==1

 
 
 **** generate retinopathy categories 

gen RetinopathyCat =0
replace RetinopathyCat=1 if  bmdiabetic_retinopathy_birm_cam_==1
replace RetinopathyCat=2 if bmsightthreateningretinopathyr2r ==1
label define RetinopathyLab 0 "No retinopathy" 1 "Diabetic retinopathy" 2 "Sight threatening retinopathy"
label value RetinopathyCat RetinopathyLab
tab RetinopathyCat

***** generate binary diabetes complications categories ***
gen DiabFootPos =0
replace DiabFootPos = 1 if DiabFoot>2 
tab DiabFootPos
tab2 DiabFootPos DiabFoot

gen DiabRetinPos =0 
replace DiabRetinPos=1 if RetinopathyCat ==2
tab DiabRetinPos

gen DiabProteinPos =0 
replace DiabProteinPos =1 if ACRCat ==2
tab DiabProteinPos


**** generate overall diabetes complications category *****

gen DiabComp = DiabFootPos + DiabRetinPos + DiabProteinPos
tab DiabComp 
tab2 DiabComp T2Diabetes, col 

***** Diabetes mortality analysis 


stcox i. DiabComp if T2Diabetes==1

stcox i. DiabComp if T1Diabetes==1

stcox i. DiabComp age_at_index i.Sex i.Ethnicity i. IMDeprivation if T2Diabetes==1

stcox i. DiabComp age_at_index i.Sex i.Ethnicity i. IMDeprivation if T1Diabetes==1
 
 
 

 
******Hypertension 
gen HTNDate =date(bd_medihypertension_bham_cam2, "YMD")
format HTNDate  %tdDD/NN/CCYY
replace HTNDate =. if HTNDate >td(01/01/2015)

gen HTN =0 
replace HTN =1 if HTNDate !=.
tab HTN

***** Generate categories for number of prescriptions of antihypertensive medication in the year precedinng the index date *****

 ***********Calcium channel blockers *****
 import delimited "/rds/projects/c/cooperjx-optimalseverity/AVF6_SeverityPhenotypes_fullDB20240410091622/AVF6_SeverityPhenotypes_fullDB20240410091622_CalciumChannelBlck_D2T.csv", clear 




gen CCBDate = date(event_date, "YMD")
format CCBDate  %tdDD/NN/CCYY

 drop if CCBDate >td(1/1/2015) 
 drop if CCBDate <td(1/1/2014)


 bysort practice_patient_id (CCBDate):gen n=_n
bysort practice_patient_id (CCBDate):gen NCCBS=_N

drop n
tab NCCBS


gen CCBCat =0 
replace CCBCat =1 if NCCBS<4
replace CCBCat = 2 if NCCBS >3  

tab NCCBS, mis 
tab CCBCat, mis 
duplicates drop practice_patient_id ,force

keep practice_patient_id NCCBS CCBCat
save "/rds/projects/c/cooperjx-optimalseverity/CCBS.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.



replace  CCBCat=0 if CCBCat ==. 



 
 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 
 
 
 ***** Angiotensin receptor blockers (ARBS)*****
 
 import delimited"/rds/projects/c/cooperjx-optimalseverity/AVF6_SeverityPhenotypes_fullDB20240410091622/AVF6_SeverityPhenotypes_fullDB20240410091622_ARBs_Luyuan.csv", clear 



gen ARBSDate = date(event_date, "YMD")
format ARBSDate  %tdDD/NN/CCYY

 drop if ARBSDate >td(1/1/2015) 
 drop if ARBSDate <td(1/1/2014)


 bysort practice_patient_id (ARBSDate):gen n=_n
bysort practice_patient_id (ARBSDate):gen NARBS=_N

drop n
tab NARBS


gen ARBS =0 
replace ARBS =1 if NARBS<4
replace ARBS = 2 if NARBS >3  

tab NARBS, mis 
tab ARBS
duplicates drop practice_patient_id ,force

keep practice_patient_id NARBS ARBS
save "/rds/projects/c/cooperjx-optimalseverity/ARBS.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.



replace ARBS=0 if ARBS ==. 



 
 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 
 


**************Angiotensin converting enzyme inhibitors (ACEi)  ******

 import delimited "/rds/projects/c/cooperjx-optimalseverity/AVF7_Severi
> tyPhenotypes_fullDB20240410095245/AVF7_SeverityPhenotypes_fullDB202404
> 10095245_ACE_Inhibitors_D2T.csv", clear 




gen ACEiDate = date(event_date, "YMD")
format ACEiDate  %tdDD/NN/CCYY

 drop if ACEiDate >td(1/1/2015) 
 drop if ACEiDate <td(1/1/2014)


 bysort practice_patient_id (ACEiDate):gen n=_n
bysort practice_patient_id (ACEiDate):gen NACEi=_N

drop n
tab NACEi


gen ACEiCat =0 
replace ACEiCat =1 if NACEi<4
replace ACEiCat = 2 if NACEi >3  

tab NACEi, mis 
tab ACEiCat, mis
duplicates drop practice_patient_id ,force

keep practice_patient_id NACEi ACEiCat
save "/rds/projects/c/cooperjx-optimalseverity/ACEI.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.



replace ACEiCat=0 if ACEiCat ==. 

tab ACEiCat
tab2 ACEiCat HTN, row mis
 
 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 
 
 
 *************Alpha blockers  ******

 import delimited "/rds/projects/c/cooperjx-optimalseverity/AVF7_SeverityPhenotypes_fullDB20240410095245/AVF7_SeverityPhenotypes_fullDB20240410095245_AlphaBlocker.csv", clear 



gen AblockerDate = date(event_date, "YMD")
format AblockerDate  %tdDD/NN/CCYY

 drop if AblockerDate >td(1/1/2015) 
 drop if AblockerDate <td(1/1/2014)


 bysort practice_patient_id (AblockerDate):gen n=_n
bysort practice_patient_id (AblockerDate):gen NAblocker=_N

drop n
tab NAblocker


gen AblockerCat =0 
replace AblockerCat =1 if NAblocker<4
replace AblockerCat = 2 if NAblocker >3  


tab AblockerCat, mis
duplicates drop practice_patient_id ,force

keep practice_patient_id NAblocker AblockerCat
save "/rds/projects/c/cooperjx-optimalseverity/Ablocker.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.



replace AblockerCat=0 if AblockerCat ==. 

tab AblockerCat
tab2 AblockerCat HTN, row mis
 
 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 
 
 
 *****************Beta blockers ***
. import delimited "/rds/projects/c/cooperjx-optimalseverity/AVF7_Severi
> tyPhenotypes_fullDB20240410095245/AVF7_SeverityPhenotypes_fullDB202404
> 10095245_BetaBlockers_OPTIMAL.csv", clear 


gen BblockerDate = date(event_date, "YMD")
format BblockerDate  %tdDD/NN/CCYY

 drop if BblockerDate >td(1/1/2015) 
 drop if BblockerDate <td(1/1/2014)


 bysort practice_patient_id (BblockerDate):gen n=_n
bysort practice_patient_id (BblockerDate):gen NBblocker=_N

drop n
tab NBblocker


gen BblockerCat =0 
replace BblockerCat =1 if NBblocker<4
replace BblockerCat = 2 if NBblocker >3  


tab BblockerCat, mis
duplicates drop practice_patient_id ,force

keep practice_patient_id NBblocker BblockerCat
save "/rds/projects/c/cooperjx-optimalseverity/Bblocker.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.



replace BblockerCat=0 if BblockerCat ==. 

tab BblockerCat
tab2 BblockerCat HTN, row mis
 
 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 
 
 
 
 
 **** generate binary catergories , patients taking > 4 prescriptions in the year preceding index date.****
 gen Ablocker = 0 
 replace Ablocker = 1 if AblockerCat > 1
 tab Ablocker, mis
 
 gen Bblocker = 0 
 replace Bblocker = 1 if BblockerCat > 1
 tab Bblocker, mis
 tab2 Bblocker HTN, col mis
 
 gen ARB =0 
  replace ARB = 1 if ARBS > 1
 tab ARB, mis
 tab2 ARB HTN, col mis
 
  gen AllDiuretics = 0 
 replace AllDiuretics = 1 if AllDiureticsCat > 1
 tab AllDiuretics, mis
 tab2 AllDiuretics HTN, col mis
 
  gen ACEinh = 0 
 replace ACEinh = 1 if ACEiCat > 1
 tab ACEinh, mis
 tab2 ACEinh HTN, col mis
 
 gen CCB = 0 
 replace CCB = 1 if CCBCat > 1
 tab CCB, mis
 tab2 CCB HTN, col mis 
 
 
 gen ACEARB =0
 replace ACEARB = 1 if ARB==1
 replace ACEARB =1 if ACEinh==1
 tab ACEARB 
 tab2 ACEARB ACEinh
 
 *** generate number of classes of antihypertensive medication 
 gen AntiHTNmeds = ACEARB + AllDiuretics + CCB + Ablocker+ Bblocker
 tab AntiHTNmeds
 tab2 AntiHTNmeds HTN , col mis 
 
 
 
 *** generate ordinal category for antihypertensive medication ****
 gen AntiHTNmedsCat = 0 
 replace AntiHTNmedsCat = 1 if AntiHTNmeds ==1 | AntiHTNmeds==2 | AntiHTNmeds ==3
 replace AntiHTNmedsCat =2 if AntiHTNmeds> 3
 tab AntiHTNmedsCat
  tab2 AntiHTNmedsCat HTN , col mis 
 
 

****** Hyperetension mortality analysis *****



 stcox i.AntiHTNmedsCat  if HTN==1

 stcox i.AntiHTNmedsCat age_at_index i.Sex i.Ethnicity i.IMD  if HTN==1



******IHD ****
gen IHDDate =date(bd_mediihdincludingmi_bham_cam_o  , "YMD")
format IHDDate  %tdDD/NN/CCYY
replace IHDDate =. if IHDDate >td(01/01/2015)

gen IHD =0 
replace IHD =1 if IHDDate !=.
tab IHD 

gen MIDate =date(bd_mediminfarction_bham_cam21  , "YMD")
format MIDate  %tdDD/NN/CCYY
replace MIDate =. if MIDate >td(01/01/2015)

gen MIheart =0 
replace MIheart =1 if MIDate !=.
tab2 MIheart IHD, col



**** IHD mortality analaysis *****

 stcox i. MIheart age_at_index i.Sex i.Ethnicity i. IMDeprivation if IHD==1
 
 stcox i. MIheart  if IHD==1
 



**********
******Heart failure  
gen HFDate =date(bd_medihf_bham_cam_final_v31 , "YMD")
format HFDate  %tdDD/NN/CCYY
replace HFDate =. if HFDate >td(01/01/2015)

gen HeartFailure =0 
replace HeartFailure =1 if HFDate !=.
tab HeartFailure

********

**** generate prescription categories for Heart failure - Loop diuretics prescriptions in 1 year prior to baseline
import delimited "/rds/projects/c/cooperjx-optimalseverity/AVF3_SeverityPhenotypes_fullDB20240304110711/AVF3_SeverityPhenotypes_fullDB20240304110711_Loop_diuretics.csv", clear 

gen DiureticsDate = date(event_date, "YMD")
format DiureticsDate  %tdDD/NN/CCYY

 drop if DiureticsDate >td(1/1/2015) 
 drop if DiureticsDate <td(1/1/2014)


 bysort practice_patient_id (DiureticsDate):gen n=_n
bysort practice_patient_id (DiureticsDate):gen NDiuretics=_N

drop n
tab NDiuretics


gen DiureticsCat =0 
replace DiureticsCat =1 if NDiuretics<7
replace DiureticsCat = 2 if NDiuretics > 6 



tab DiureticsCat 
replace DiureticsCat=0 if DiureticsCat ==. 

tab2 DiureticsCat HeartFailure, mis col
 
 

save "/rds/projects/c/cooperjx-optimalseverity/Diuretics.dta", replace
***

merge 1:1 practice_patient_id using  "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta"
drop _merge
drop if YearofBirth ==.

 save "/rds/projects/c/cooperjx-optimalseverity/SeverityPhenotypesData.dta", replace 

 
 **** Heart failure mortality analysis 
 
 stcox i.DiureticsCat  if HeartFailure==1

 stcox i.DiureticsCat age_at_index i.Sex i.Ethnicity i.IMD  if HeartFailure==1



 ************CKD**************************

gen CKDDate =date(bd_medickdstage3to5_bham_cam4 , "YMD")
format CKDDate  %tdDD/NN/CCYY
replace CKDDate =. if CKDDate >td(01/01/2015)

gen CKD3to5 =0 
replace CKD3to5 =1 if CKDDate !=.
tab CKD3to5

**** ACR in 3 years (36 months) prior to baseline 
 gen ACRDate =date(bd_urine_albumincreatinine_ratio , "YMD")
format ACRDate  %tdDD/NN/CCYY
replace ACRDate =. if ACRDate >td(01/01/2015)


 gen ACR36m = 0 
 replace ACR36m = 1 if ACRDate >td(1/1/2012) 
 replace ACR36m =0 if ACRDate==.
 tab ACR36m
 
 
gen ACRresult1 = b_urine_albumincreatinine_ratio_ if ACR36m ==1


sum ACRresult1, detail

replace ACRresult1 =. if ACRresult1 > 1500

gen ACRDate2 =date(bd_urine_microalbumincreatinine_ , "YMD")
format ACRDate2  %tdDD/NN/CCYY
replace ACRDate2 =. if ACRDate2 >td(01/01/2015)
 
 gen ACR36m2 = 0 
 replace ACR36m2 = 1 if ACRDate2 >td(1/1/2012) 
 replace ACR36m2 =0 if ACRDate2 ==.
 tab ACR36m2
 
 gen ACRresult2=b_urine_microalbumincreatinine_r if ACR36m2==1
 replace ACRresult2 =. if ACRresult2 > 1000
 tab2 ACR36m ACR36m2, mis
 
 
 
 gen ACRDate3 =date( bd_albumin__creatinine_ratio_3_3  , "YMD")
format ACRDate3  %tdDD/NN/CCYY
replace ACRDate3 =. if ACRDate3 >td(01/01/2015)
 
 gen ACR36m3 = 0 
 replace ACR36m3 = 1 if ACRDate3 >td(1/1/2012) 
 replace ACR36m3 =0 if ACRDate3 ==.
 tab ACR36m3
 
 gen ACRresult3=b_albumin__creatinine_ratio_3_va if ACR36m3==1
 replace ACRresult3 =. if ACRresult3 > 1000
 tab2 ACR36m ACR36m3, mis

 
**Final ACR results
gen B_ACR = ACRresult3
replace B_ACR = ACRresult2 if ACRresult2!=. 
replace B_ACR = ACRresult1 if ACRresult1!=. 
 


sum B_ACR, detail



***ACR categories
count if B_ACR >1700 & B_ACR !=.   // EGFR cohort 6
replace B_ACR = . if B_ACR > 1700
label var B_ACR "ACR mg/mmol"
misstable summarize B_ACR

recode B_ACR (min/2.9999999999 = 0 "<3 (A1)") (3/30 = 1 "3-30 (A2)") (30.0000000001/1700 = 2 ">30 (A3)") (missing = 88 "missing or implausible values"), gen(ACRCat)
label var ACRCat "ACR categories at baseline mg/mmol"
tab ACRCat 

tab2 ACRCat T2Diabetes, col
 tab2 ACRCat T1Diabetes, col  
 tab2 ACRCat CKD3to5, col

 **********Creatinine  in 3 years (36 months) before index date *************
 gen CreatDate1 =date(  bd_serum_creatinine_4_4   , "YMD")
format CreatDate1  %tdDD/NN/CCYY
replace CreatDate1=. if CreatDate1 >td(01/01/2015)
 
 gen Creat36m1 = 0 
 replace Creat36m1  = 1 if CreatDate1 >td(1/1/2012) 
 replace Creat36m1 =0 if CreatDate1 ==.
 tab Creat36m1
 
 gen CreatDate2 =date(   bd_plasma_creatinine_level_5_5  , "YMD")
format CreatDate2  %tdDD/NN/CCYY
replace CreatDate2=. if CreatDate2 >td(01/01/2015)
 
 gen Creat36m2 = 0 
 replace Creat36m2  = 1 if CreatDate2 >td(1/1/2012) 
 replace Creat36m2 =0 if CreatDate2 ==.
 tab Creat36m2
 

 
 **** replace implausible values *** 
 *** keep only verified units data **
 
 gen Creatvalue =b_serum_creatinine_4_value_4
 replace Creatvalue=. if  b_serum_creatinine_4_value_4 <1
  replace Creatvalue=. if  b_serum_creatinine_4_value_4 > 14000
 
 replace Creatvalue=. if Creat36m1 ==0
 replace Creatvalue=. if b_serum_creatinine_4_numunit_4 != "umol/L"
 
gen Creatvalue2 = b_plasma_creatinine_level_5_valu
replace Creatvalue2=. if b_plasma_creatinine_level_5_valu <1

replace Creatvalue2=. if Creat36m2 ==0
replace Creatvalue2 =. if b_plasma_creatinine_level_5_numu != "umol/L"




*******create eGFR categories with CKD-EPI formula

*** use latest available data****
generate CreatinineDate = max(CreatDate1, CreatDate2)

format CreatinineDate %tdDD/NN/CCYY

gen CreatResultFinal = .
replace CreatResultFinal= Creatvalue if CreatinineDate == CreatDate1
replace CreatResultFinal = Creatvalue2 if CreatinineDate ==CreatDate2 


gen ageatcreatinine = (CreatinineDate - YearofBirth)/ 365.25
sum ageatcreatinine, detail
gen CalculatedGFR = .
replace CalculatedGFR = 141 * min((CreatResultFinal * 0.0113122/0.7), 1)^(-0.329) * max((CreatResultFinal * 0.0113122/0.7), 1)^(-1.209) * (0.993^ageatcreatinine) * (1.018) * (1.159) if CreatResultFinal > 0 & CreatResultFinal!=. & Sex == 2  & Ethnicity ==2   
replace CalculatedGFR = 141 * min((CreatResultFinal * 0.0113122/0.7), 1)^(-0.329) * max((CreatResultFinal * 0.0113122/0.7), 1)^(-1.209) * (0.993^ageatcreatinine) * (1.018) if CreatResultFinal > 0 & CreatResultFinal!=. & Sex == 2  & Ethnicity !=2
replace CalculatedGFR = 141 * min((CreatResultFinal * 0.0113122/0.9), 1)^(-0.411) * max((CreatResultFinal * 0.0113122/0.9), 1)^(-1.209) * (0.993^ageatcreatinine) * (1.159) if CreatResultFinal > 0 & CreatResultFinal!=. & Sex == 1  & Ethnicity ==2
replace CalculatedGFR = 141 * min((CreatResultFinal * 0.0113122/0.9), 1)^(-0.411) * max((CreatResultFinal * 0.0113122/0.9), 1)^(-1.209) * (0.993^ageatcreatinine) if CreatResultFinal > 0 & CreatResultFinal!=. & Sex == 1  & Ethnicity !=2 

count if CreatResultFinal ==0  // 346 excluded
// remove implausible GFR
replace CalculatedGFR = . if CalculatedGFR > 200  // 584 replaced
label var CalculatedGFR "eGFR --> ml/min/1.73 m²"
misstable summarize CalculatedGFR
sum CalculatedGFR, detail


recode CalculatedGFR (min/14.9999999999 = 6 "<15 (Stage 5)") (15/29.9999999999 = 5 "15-29 (Stage 4)") (30/44.9999999999 = 4 "30-44 (Stage 3b)") (45/59.9999999999 = 3 "45-59 (Stage 3a)") (60/89.9999999999 = 2 "60-89 (Stage 2)") (90/300 = 1 ">=90 (Stage 1)") (missing = 88 "missing or implausible values"), gen(CalculatedGFRCat)
label var CalculatedGFRCat "eGFR categories at baseline"
tab CalculatedGFRCat 





********CKD stages by CalculatedGFR Only
gen CKDGFRCat =.
replace CKDGFRCat = 4 if CalculatedGFRCat ==6
replace CKDGFRCat = 3 if CalculatedGFRCat ==5
replace CKDGFRCat = 2 if CalculatedGFRCat ==4
replace CKDGFRCat = 1 if CalculatedGFRCat ==3
label define CKDGFRcatlabel2  1 "CKD 3a" 2 "CKD 3b" 3 "CKD 4" 4 "CKD 5"
label value CKDGFRCat CKDGFRcatlabel2
tab CKDGFRCat, mis



 
 ************CKD  mortality analysis *********


stcox i.CKDGFRCat if CKDGFRCat !=.
stcox i. CKDGFRCat age_at_index i.Sex i.Ethnicity i. IMDeprivation if CKDGFRCat !=.


 
 
 
 
 
 **************************************************************************
 ****Aortic aneursyms*****
 gen AAADate =date(bd_mediaorticaneurysm_bham_cam8  , "YMD")
format AAADate  %tdDD/NN/CCYY
replace AAADate =. if AAADate >td(01/01/2015)

gen AorticAneursym =0 
replace AorticAneursym =1 if AAADate !=.
tab AorticAneursym
  
 ********** Aortic anerysms severity categories *****

i
   gen InterventionAAADate =date(bd_mediinterventionaorticaneurys , "YMD")
format InterventionAAADate  %tdDD/NN/CCYY
replace InterventionAAADate=. if InterventionAAADate >td(01/01/2015)

gen InterventionAAA = 0 
replace InterventionAAA =1 if InterventionAAADate !=.
tab InterventionAAA
tab2 InterventionAAA AorticAneursym, col mis 
 
  gen EmergAAADate =date(bd_mediemergencyaorticaneurysm_b , "YMD")
format EmergAAADate  %tdDD/NN/CCYY
replace EmergAAADate =. if EmergAAADate >td(01/01/2015)

gen EmergAAA = 0 
replace EmergAAA =1 if EmergAAADate !=.
tab EmergAAA
tab2 EmergAAA AorticAneursym, col mis 

gen AAASeverity =0 
replace AAASeverity =1 if InterventionAAA ==1
replace AAASeverity = 2 if EmergAAA==1
tab AAASeverity
tab2 AAASeverity AorticAneursym, col mis

**** aortic aneurysms mortality analysis 

 stcox i. AAASeverity  if AorticAneursym==1

stcox i.AAASeverity age_at_index i.Sex i.Ethnicity i. IMDeprivation if AorticAneursym==1

 
 *************************************************************************
 ****PVD *****
 gen PVDDate =date(bd_medipvd_bham_cam_v39  , "YMD")
format PVDDate  %tdDD/NN/CCYY
replace PVDDate =. if Date >td(01/01/2015)

gen PVD =0 
replace PVD =1 if PVDDate !=.
tab PVD
 
 
  gen SevPVDDate =date( bd_medisevere_pvd_bham_cam23   , "YMD")
format SevPVDDate  %tdDD/NN/CCYY
replace SevPVDDate =. if SevPVDDate >td(01/01/2015)

gen SevPVD =0 
replace SevPVD =1 if SevPVDDate !=.
tab SevPVD
tab2 PVD SevPVD, row


replace SevPVD =0 if b_medisevere_pvd_bham_cam23==742481000006118


replace SevPVD =0 if b_medisevere_pvd_bham_cam23==309177010
replace SevPVD =0 if b_medisevere_pvd_bham_cam23==443199013
replace SevPVD =0 if b_medisevere_pvd_bham_cam23==357895013
replace SevPVD =0 if b_medisevere_pvd_bham_cam23==450665015
replace SevPVD =0 if b_medisevere_pvd_bham_cam23==350533013
replace SevPVD =0 if b_medisevere_pvd_bham_cam23==2377871000000112
 tab2 PVD SevPVD, row
 
 
   gen AmpDate =date(  bd_mediamputationall_zhaonan24   , "YMD")
format AmpDate  %tdDD/NN/CCYY
replace AmpDate =. if AmpDate >td(01/01/2015)

gen AmpPVD =0 
replace AmpPVD =1 if AmpDate !=.
tab AmpPVD
tab2 PVD AmpPVD, row

tab2 AmpPVD DiabFootAmp, row 

gen PVDCat=0
replace PVDCat=1 if SevPVD==1
replace PVDCat=2 if AmpPVD==1
 tab PVDCat
 tab2 PVDCat PVD, col mis
 
 
 
 **** PVD mortality analysis ***
 
 stcox i. PVDCat  if PVD==1

stcox i. PVDCat age_at_index i.Sex i.Ethnicity i. IMDeprivation if PVD==1


 
 ********DEPRESSION *********
 gen DepressionDate = date(bd_medidepression_birm_cam10, "YMD")
format DepressionDate  %tdDD/NN/CCYY

replace DepressionDate =. if DepressionDate >td(01/01/2015)
gen Depression=0
replace Depression =1 if DepressionDate !=.
tab Depression
 
 *********** Psychiatric inpatient admission ****
 gen PsychAdmDate = date(bd_medipsychiatiricadmission25, "YMD")
format PsychAdmDate  %tdDD/NN/CCYY

replace PsychAdmDate =. if PsychAdmDate >td(01/01/2015)
gen PsychAdm=0
replace PsychAdm =1 if PsychAdmDate !=.
tab PsychAdm
tab2 Depression PsychAdm, row

****** ECT *****
gen ECTDate = date(bd_medielectroconvulsivetherapy2 , "YMD")
format ECTDate  %tdDD/NN/CCYY

replace ECTDate =. if ECTDate >td(01/01/2015)
gen ECT=0
replace ECT =1 if ECTDate !=.
tab ECT
tab2 Depression ECT, row 


 ***** Referral to secondary care Mental health***

gen SecondaryCareMHDate =date( bd_medireferral_secondarycare_me , "YMD")
format SecondaryCareMHDate  %tdDD/NN/CCYY
replace SecondaryCareMHDate  =. if SecondaryCareMHDate  >td(01/01/2015)

gen SecondaryCareMH=0 
replace SecondaryCareMH =1 if SecondaryCareMHDate !=.
tab SecondaryCareMH
tab2 Depression SecondaryCareMH, row 
********************************************


**** Depression Severity categories********

gen DepressionSev = 0 
replace DepressionSev =1 if SecondaryCareMH==1
replace DepressionSev =2 if PsychAdm==1 
replace DepressionSev =2 if ECT==1
tab DepressionSev
tab2 Depression DepressionSev, row 
 
 
 
 **** Depression severity mortality analysis 
 stcox i. DepressionSev  if Depression==1

stcox i. DepressionSev age_at_index i.Sex i.Ethnicity i. IMDeprivation if Depression==1

 

*****************************

 

 ****************
 *****PREVALENCE 
 tab T2Diabetes
 tab T1Diabetes
tab HTN
 tab IHD
 tab HeartFailure
 tab AorticAneursym
 tab CKD3to5
 tab PVD
 tab Depression 
 
 
 ******* IHD*********
 
drop if IHD != 1 
tab Sex 
tab agecat
tab Ethnicity 
tab IMDeprivation

sum age_at_index, detail 

tab MIheart 
tab2 MIheart Sex, row 
tab2 MIheart agecat, row 
tab2 MIheart Ethnicity, row
tab2 MIheart IMDeprivation, row 

bysort MIheart: sum age_at_index, detail 


//generate baseline tables 


 tab Sex 
tab agecat
tab Ethnicity 
tab IMDeprivation

sum age_at_index, detail 


tab CKDGFRCat, MIS
tab2 CKDGFRCat Sex, row 
tab2 CKDGFRCat agecat, row 
tab2 CKDGFRCat Ethnicity, row
tab2 CKDGFRCat IMDeprivation, row 

bysort CKDGFRCat: sum age_at_index, detail 

tab2 CKDGFRCat CalculatedCKD, mis


 *** T1Diabetes
tab DiabComp, mis , if T1Diabetes==1
tab2 DiabComp Sex, row , if T1Diabetes==1
tab2 DiabComp agecat, row , if T1Diabetes==1
tab2 DiabComp Ethnicity, row, if T1Diabetes==1
tab2 DiabComp IMDeprivation, row , if T1Diabetes==1

sum age_at_index, detail , if T1Diabetes==1
bysort DiabComp: sum age_at_index, detail , if T1Diabetes==1




 *** T2Diabetes
tab DiabComp, mis , if T2Diabetes==1
tab2 DiabComp Sex, row , if T2Diabetes==1
tab2 DiabComp agecat, row , if T2Diabetes==1
tab2 DiabComp Ethnicity, row, if T2Diabetes==1
tab2 DiabComp IMDeprivation, row , if T2Diabetes==1

sum age_at_index, detail , if T2Diabetes==1
bysort DiabComp: sum age_at_index, detail , if T2Diabetes==1


 *** PVD

tab PVDCat, mis , if PVD==1
tab2 PVDCat Sex, row , if PVD==1
tab2 PVDCat agecat, row , if PVD==1
tab2 PVDCat Ethnicity, row, if PVD==1
tab2 PVDCat IMDeprivation, row , if PVD==1

sum age_at_index, detail , if PVD==1
bysort PVDCat: sum age_at_index, detail , if PVD==1

******
 ***Heart failure

tab DiureticsCat, mis , if HeartFailure==1
tab2 DiureticsCat Sex, row , if HeartFailure==1
tab2 DiureticsCat agecat, row , if HeartFailure==1
tab2 DiureticsCat Ethnicity, row, if HeartFailure==1
tab2 DiureticsCat IMDeprivation, row , if HeartFailure==1

sum age_at_index, detail , if HeartFailure==1
bysort DiureticsCat: sum age_at_index, detail , if HeartFailure==1

******
 ***Depression

tab DepressionSev, mis , if Depression==1
tab2 DepressionSev Sex, row , if Depression==1
tab2 DepressionSev agecat, row , if Depression==1
tab2 DepressionSev Ethnicity, row, if Depression==1
tab2 DepressionSev IMDeprivation, row , if Depression==1

sum age_at_index, detail , if Depression==1
bysort DepressionSev: sum age_at_index, detail , if Depression==1

******
**Hypertension 

tab AntiHTNmedsCat, mis , if HTN==1
tab2 AntiHTNmedsCat Sex, row , if HTN==1
tab2 AntiHTNmedsCat agecat, row , if HTN==1
tab2 AntiHTNmedsCat Ethnicity, row, if HTN==1
tab2 AntiHTNmedsCat IMDeprivation, row , if HTN==1

sum age_at_index, detail , if HTN==1
bysort AntiHTNmedsCat: sum age_at_index, detail 

drop if HTN =0 
**** AAA

tab AAASeverity, mis , if AorticAneursym==1
tab2 AAASeverity Sex, row , if AorticAneursym==1
tab2 AAASeverity agecat, row , if AorticAneursym==1
tab2 AAASeverity Ethnicity, row, if AorticAneursym==1
tab2 AAASeverity IMDeprivation, row , if AorticAneursym==1

sum age_at_index, detail , if AorticAneursym==1
bysort AAASeverity: sum age_at_index, detail
drop if AorticAneursym ==0

