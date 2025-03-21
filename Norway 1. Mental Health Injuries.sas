DM			'LOG; CLEAR; ;OUT; CLEAR; ';
%LET		program = M:\p1074-renateh\2023_MHInjuries\01_MHInjuries_Mar2024.sas;
FOOTNOTE	"&program on &sysdate";

***************************************************************************************************;
* For:				Norway
* Paper:			Norway: MH -> Injuries
* Programmer:		Renate Houts
* File:				M:\p1074-renateh\2023_MHInjuries\01_MHInjuries_Mar2024.sas
* Modification Hx:	Oct-2023	OR's and HR's connecting injuries and MH diagnoses
*					Mar-2024	Prevalences, HR's by Age & Sex, HR's by MH-dx & Body Region, 
*								Risk Differences
*
***************************************************************************************************;

libname rawdat	"N:\durable\Data22\processed_data\ForRenate";
libname mhinj	"M:\p1074-renateh\2023_MHInjuries";

proc format;
	value SEX
		1 = "Male"
		2 = "Female";
	value NOYES
		0 = "No"
		1 = "Yes";
	value MHDX
		-1 = "MHDX: P-code with no number"
		 1 = "Acute stress reaction"
		 2 = "ADHD"
		 3 = "Anxiety" 
		 4 = "Dementia/Memory problems"
		 5 = "Depression"
		 6 = "Developmental delay/Learning problems"
		 7 = "Eating disorder"
		 8 = "Phobia/Compulsive disorder"
		 9 = "Psychosis"
		10 = "PTSD"
		11 = "Sexual concern"
		12 = "Sleep disturbance"		
		13 = "Somatization"
		14 = "Substance abuse"
		15 = "Suicide/Suicide attempt"
		16 = "Child/Adolescent behavior symptom/complaint"
		17 = "Continence issues"
		18 = "Personality disorder"
		19 = "Neuresthenia/surmenage (chronic fatigue)"
		20 = "Phase of life problem adult"
		21 = "Stammering/stuttering/tic"
		22 = "Fear of mental disorder"
		23 = "Feeling/behaving irritable/angry"
		24 = "Other psychological symptom/disease";
	value DXALL
		 1 = "Acute stress reaction"
		 2 = "ADHD"
		 3 = "Anxiety" 
		 4 = "Dementia/Memory problems"
		 5 = "Depression"
		 6 = "Developmental delay/Learning problems"
		 7 = "Eating disorder"
		 8 = "Phobia/Compulsive disorder"
		 9 = "Psychosis"
		10 = "PTSD"
		11 = "Sexual concern"
		12 = "Sleep disturbance"		
		13 = "Somatization"
		14 = "Substance abuse"
		16 = "Child/Adolescent behavior symptom/complaint"
		17 = "Continence issues"
		18 = "Personality disorder"
		19 = "Neuresthenia/surmenage (chronic fatigue)"
		20 = "Phase of life problem adult"
		21 = "Stammering/stuttering/tic"
		22 = "Fear of mental disorder"
		23 = "Feeling/behaving irritable/angry"
		24 = "Psychological symptom/complaint/disorder, NOS"
		25 = "Other: Psychological"
		51 = "General & Unspecified"
		52 = "Blood"
		53 = "Digestive"
		54 = "Eye"
		55 = "Ear"
		56 = "Musculoskeletal"
		57 = "Neurological"
		58 = "Respriatory"
		59 = "Skin"
		60 = "Urological"
		61 = "Pregnancy"
		62 = "Genital"
		63 = "Other: B, R, U, W, X/Y";
	value CHAPTER
		 1 = "General & Unspecified"
		 2 = "Blood, Blood Forming Organs & Immune Mechanism"
		 3 = "Digestive"
		 4 = "Eye"
		 5 = "Ear"
		 6 = "Cardiovascular"
		 7 = "Musculoskeletal"
		 8 = "Neurological"
		 9 = "Psychological"
		10 = "Respiratory"
		11 = "Skin"
		12 = "Endocrine/Metabolic & Nutritional"
		13 = "Urological"
		14 = "Pregnancy, Childbearing, Family planning"
		15 = "Female genital"
		16 = "Male genital"
		17 = "Social Problems";
	value EDTRUNC
		0 = "No education and pre-school education (under school age)"
		1 = "Compulsary education (1-10y of ed)"
		2 = "Intermediate education (11-14y ed)"
		3 = "Higher education (14-20+y of ed)"
		9 = "Unspecified";
run;

*******************************;
* DATA PREP                    ;
*******************************;

* Read in medical records and bring down to ages 10-60;
data medrec;
	set rawdat.MedRec_23Feb2024;

	if age_start >= 10 & age_start <= 60;
run;

* Code diagnoses into categories we're using;
data medrec1;
	set medrec;

	* Code mental health into diagnoses;
	if DIAG in ("P02")                                      then MHdx = 1;
		else if DIAG in ("P81")                             then MHdx = 2;
		else if DIAG in ("P01", "P74")                      then MHdx = 3;
		*else if DIAG in ("P05", "P20", "P70")               then MHdx = 4; * Memory disturbance/Dementia (not used);
		else if DIAG in ("P03", "P76")                      then MHdx = 5;		
		else if DIAG in ("P24", "P28", "P85")               then MHdx = 6;
		else if DIAG in ("P11", "P86")                      then MHdx = 7;
		else if DIAG in ("P79")                      		then MHdx = 8;
		else if DIAG in ("P71", "P72", "P73", "P98")		then MHdx = 9;
		else if DIAG in ("P82")								then MHdx = 10;		
		else if DIAG in ("P07", "P08", "P09")				then MHdx = 11;
		else if DIAG in ("P06")								then MHdx = 12;
		else if DIAG in ("P75")							    then MHdx = 13;
		else if DIAG in ("P15", "P16", "P17", "P18", "P19") then MHdx = 14;
		*else if DIAG in ("P77")								then MHdx = 15;	* Suicide/Suicide attempt (not used);
		else if DIAG in ("P22", "P23")                      then MHdx = 16;
		else if DIAG in ("P12", "P13")                      then MHdx = 17;
		else if DIAG in ("P80")                             then MHdx = 18;
		else if DIAG in ("P78")                             then MHdx = 19;
		else if DIAG in ("P25")                             then MHdx = 20;
		else if DIAG in ("P10")                             then MHdx = 21;
		else if DIAG in ("P27")                             then MHdx = 22;
		else if DIAG in ("P04")                             then MHdx = 23;
		else if DIAG in ("P29", "P99")                      then MHdx = 24;

	if codetype = "inj" then injury  = 1;
		else injury = 0;
	if MHdx ne . then anyMH = 1;
		else anyMH = 0;

	* Combine male/female genital;
	if diag_chapter = "Y" then diag_chapter = "X";

	* Create "other" category for low-base-rate codes (not analyzed beyond inclusion in any-injury or any-MH);
	* NOTE: To get prevalences/statistics on the individual codes, comment out the following 2 lines;
	if diag_chapter in ("B", "R", "U", "W", "X") then diag_chapter = "O";
	if MHdx in (7, 13, 16, 17, 20, 21, 22, 23)   then MHdx = 25;

	* Keep only codes we're using;
	if injury = 1 or anyMH = 1 then keep = 1;

	if keep = 1;

	drop keep;

	format MHdx MHDX.;
run;

/*
* Check who encounters were with (e.g., doctors, physical therapists, etc);
proc freq data = medrec1;
	table diag_chapter*FAGOMRAADE_KODE;
	where injury = 1;
run;
proc freq data = medrec1;
	table MHdx*FAGOMRAADE_KODE;
	where injury = 0;
run;
*/

* Import location and education for IPWs;
proc import file = "N:\durable\Data22\original_data\k2_-w19_1011_4b_bostedskommune_ut.txt"
	out = locate0
	dbms = dlm
	replace;
	delimiter = ';';
	guessingrows = 10000;
run;
proc import file = "N:\durable\Data22\processed_data\ForRenate\Education_ALL_Feb2024.csv"
	out = educ0
	dbms = dlm
	replace;
	delimiter = ',';
	guessingrows = 10000;
run;
data locate1;
	set locate0;

	loc06 = bostedskommune_01_01_2006;

	keep w19_1011_lnr_k2_ loc06;
run;

proc sort data = locate1;   by w19_1011_lnr_k2_; run;
proc sort data = educ0;     by w19_1011_lnr_k2_; run;

* Bring analysis sample down to ages [10-60] on 01-Jan-2006;
data demog;
	merge rawdat.Demog_23Feb2024
		  locate1 educ0 (keep = w19_1011_lnr_k2_ education ed_flag);
	by w19_1011_lnr_k2_;

	* Limit to ages [10-60] on 01-Jan-2006;
	if age_start >= 10 & age_start <= 60;

	* Recode sex;
	if sex = 1 then male = 1;
		else if sex = 2 then male = 0;

	* Create age groups;
	if age_start >= 10 and age_start < 20 then age_band = 10;
		else if age_start >= 20 and age_start < 30  then age_band = 20;
		else if age_start >= 30 and age_start < 40  then age_band = 30;
		else if age_start >= 40 and age_start < 50  then age_band = 40;
		else if age_start >= 50 and age_start <= 60 then age_band = 50;

	* Collapse location into county;
	* NOTE: N = 15 missing location;
	county = FLOOR(loc06/100);

	
	* N = 845 deleted for missing county (N = 11), education (N = 830) or both (N = 4);
	if county ne .     then have_loc = 1; else have_loc = 0;
	if education ne .  then have_edu = 1; else have_edu = 0;
	if age_start ne .  then have_age = 1; else have_age = 0;
	if male ne .       then have_sex = 1; else have_sex = 0;
	
	if have_loc = 0 or have_edu = 0 then delete;

	keep w19_1011_lnr_k2_ DOB DOD male county education ed_flag age_start age_band /*have_loc have_edu have_age have_sex*/;
run;

proc datasets; delete educ0 locate0 locate1; run; quit;

* Range of birth dates;
proc freq data = demog;
	table DOB;
run;

/*
proc freq data = demog;
	table have_edu*have_loc*have_age*have_sex / list missing;
run;
*/

* IDs for those aged [10-60] with data for IPWs;
data insample;
	set demog;
	keep w19_1011_lnr_k2_;
run;

* Create one variable for diagnosis types;
data medrec2;
	merge insample (in = indem) medrec1;
	by w19_1011_lnr_k2_;

	if indem;

	dx_all = MHdx;

	if injury = 1 and diag_chapter = "A" then dx_all = 51;
		else if injury = 1 and diag_chapter = "B" then dx_all = 52;
		else if injury = 1 and diag_chapter = "D" then dx_all = 53;
		else if injury = 1 and diag_chapter = "F" then dx_all = 54;
		else if injury = 1 and diag_chapter = "H" then dx_all = 55;
		else if injury = 1 and diag_chapter = "L" then dx_all = 56;
		else if injury = 1 and diag_chapter = "N" then dx_all = 57;
		else if injury = 1 and diag_chapter = "R" then dx_all = 58;
		else if injury = 1 and diag_chapter = "S" then dx_all = 59;
		else if injury = 1 and diag_chapter = "U" then dx_all = 60;
		else if injury = 1 and diag_chapter = "W" then dx_all = 61;
		else if injury = 1 and diag_chapter = "X" then dx_all = 62;
		else if injury = 1 and diag_chapter = "O" then dx_all = 63;

	format dx_all DXALL.;
run;

* Create wide file with indicator variables for ever having dx;
proc sort data = medrec2 out = uniqdx nodupkey; by w19_1011_lnr_k2_ dx_all; run;

* Create file with diagnoses meeting prevalence criteria;
* NOTE:	Variables commented out did not meet the "experienced by at least 1% of the population" criteria
* 		and were collapsed into "other" categories; 
data medrec_wide;
	array dx [23]	any_str any_adhd any_anx any_dep  any_dev /*any_eat*/ any_phb any_psy any_ptsd any_sex 
					any_slp /*any_som*/  any_sub /*any_chad any_con*/ any_per any_crf /*any_pha any_stu any_fmh
					any_irr*/ any_NOS  any_oth
					any_A /*any_B*/ any_D any_F any_H any_L any_N /*any_R*/ any_S /*any_U any_W any_X*/ any_O;

	do i = 1 to 24 until (last.w19_1011_lnr_k2_);
		set uniqdx;
		by w19_1011_lnr_k2_;
	
		if dx_all =  1 then any_str  = 1;
		if dx_all =  2 then any_adhd = 1;
		if dx_all =  3 then any_anx  = 1;
		if dx_all =  5 then any_dep  = 1;
		if dx_all =  6 then any_dev  = 1;
		*if dx_all =  7 then any_eat  = 1;
		if dx_all =  8 then any_phb  = 1;
		if dx_all =  9 then any_psy  = 1;
		if dx_all = 10 then any_ptsd = 1;
		if dx_all = 11 then any_sex  = 1;
		if dx_all = 12 then any_slp  = 1;
		*if dx_all = 13 then any_som  = 1;
		if dx_all = 14 then any_sub  = 1;
		*if dx_all = 16 then any_chad = 1;
		*if dx_all = 17 then any_con  = 1;
		if dx_all = 18 then any_per  = 1;
		if dx_all = 19 then any_crf  = 1;
		*if dx_all = 20 then any_pha  = 1;
		*if dx_all = 21 then any_stu  = 1;
		*if dx_all = 22 then any_fmh  = 1;
		*if dx_all = 23 then any_irr  = 1;
		if dx_all = 24 then any_NOS  = 1;
		if dx_all = 25 then any_oth  = 1;

		if dx_all = 51 then any_A    = 1;
		*if dx_all = 52 then any_B    = 1;
		if dx_all = 53 then any_D    = 1;
		if dx_all = 54 then any_F    = 1;
		if dx_all = 55 then any_H    = 1;
		if dx_all = 56 then any_L    = 1;
		if dx_all = 57 then any_N    = 1;
		*if dx_all = 58 then any_R    = 1;
		if dx_all = 59 then any_S    = 1;
		*if dx_all = 60 then any_U    = 1;
		*if dx_all = 61 then any_W    = 1;
		*if dx_all = 62 then any_X    = 1;
		if dx_all = 63 then any_O    = 1;
	end;

	keep w19_1011_lnr_k2_ 
		 any_str any_adhd any_anx any_dep  any_dev /*any_eat*/ any_phb any_psy any_ptsd any_sex 
		 any_slp /*any_som*/  any_sub /*any_chad any_con*/ any_per any_crf /*any_pha any_stu any_fmh
		 any_irr*/ any_NOS  any_oth
		 any_A /*any_B*/ any_D any_F any_H any_L any_N /*any_R*/ any_S /*any_U any_W any_X*/ any_O;
run;

data medrec_wide;
	merge demog (in = indem) medrec_wide;
	by w19_1011_lnr_k2_;

	if indem;

	* Those without a specific code were assumed to not have the disorder and coded 0;
	array dx [23]	any_str any_adhd any_anx any_dep  any_dev /*any_eat*/ any_phb any_psy any_ptsd any_sex 
					any_slp /*any_som*/  any_sub /*any_chad any_con*/ any_per any_crf /*any_pha any_stu any_fmh
					any_irr*/ any_NOS  any_oth
					any_A /*any_B*/ any_D any_F any_H any_L any_N /*any_R*/ any_S /*any_U any_W any_X*/ any_O;

	do i = 1 to 23;
		if dx[i] = . then dx[i] = 0;
	end;

	* Create "any Mental Disorder" and "any Injury";
	if SUM(any_str, any_adhd, any_anx, any_dep,  any_dev, /*any_eat,*/ any_phb, any_psy, any_ptsd, any_sex, 
		   any_slp, /*any_som,*/  any_sub, /*any_chad, any_con,*/ any_per, any_crf, /*any_pha, any_stu,  any_fmh,
		   any_irr,*/ any_NOS,  any_oth) > 0 then any_MH = 1;
		else any_MH = 0;

	if SUM(any_A, /*any_B,*/ any_D, any_F, any_H, any_L, any_N, /*any_R,*/ any_S, /*any_U, any_W, any_X*/ any_O) > 0 then any_inj = 1;
		else any_inj = 0;

	* Create "clean" comparison group for injuries in specific body chapter codes;
	array dx1 [8]	any_A  any_D  any_F  any_H  any_L  any_N  any_S  any_O;
	array dx2 [8]	any_Ac any_Dc any_Fc any_Hc any_Lc any_Nc any_Sc any_Oc;
	
	do i = 1 to 8;
		dx2[i] = dx1[i];
		if dx2[i] = 0 and any_inj = 1 then dx2[i] = .;
	end;

	drop i;
run;

* Create stabilized ipw's;
* See: http://www.baileydebarmore.com/epicode/calculating-ipw-and-smr-in-sas;
* 		Unstabilized IPW's create pseudopopulation 2X size of observed population 
*       and generaly results in wider confidence intervals
*		BUT, our N's are so large that it really doesn't matter which is used;

%macro get_ipw (outcm = );
	proc logistic data = medrec_wide;
		class county;
		model any_&outcm (event = '1') = male county education age_start;
		output out = &outcm._den p = d_&outcm;
	proc logistic data = medrec_wide;
		model any_&outcm (event = '1') = ;
		output out = &outcm._num p = n_&outcm;
	run;
%mend get_ipw;

%get_ipw(outcm = MH);
%get_ipw(outcm = str);
%get_ipw(outcm = adhd);
%get_ipw(outcm = anx);
%get_ipw(outcm = dep);
%get_ipw(outcm = dev);
%get_ipw(outcm = phb);
%get_ipw(outcm = psy);
%get_ipw(outcm = ptsd);
%get_ipw(outcm = sex);
%get_ipw(outcm = slp);
%get_ipw(outcm = sub);
%get_ipw(outcm = per);
%get_ipw(outcm = crf);
%get_ipw(outcm = NOS);
%get_ipw(outcm = oth);

data medrec_wide_ipw;
	merge medrec_wide MH_den str_den adhd_den anx_den dep_den dev_den phb_den psy_den ptsd_den sex_den slp_den sub_den per_den crf_den NOS_den oth_den
					  MH_num str_num adhd_num anx_num dep_num dev_num phb_num psy_num ptsd_num sex_num slp_num sub_num per_num crf_num NOS_num oth_num;
	by w19_1011_lnr_k2_;

	array any [16]  any_MH any_str any_adhd any_anx any_dep  any_dev any_phb any_psy any_ptsd any_sex any_slp any_sub any_per any_crf any_NOS any_oth;
	array num [16]  n_MH n_str n_adhd n_anx n_dep  n_dev n_phb n_psy n_ptsd n_sex n_slp n_sub n_per n_crf n_NOS n_oth;
	array den [16]  d_MH d_str d_adhd d_anx d_dep  d_dev d_phb d_psy d_ptsd d_sex d_slp d_sub d_per d_crf d_NOS d_oth;
	array ipw [16]  MH_ipw str_ipw adhd_ipw anx_ipw dep_ipw dev_ipw phb_ipw psy_ipw ptsd_ipw sex_ipw slp_ipw sub_ipw per_ipw crf_ipw NOS_ipw oth_ipw;

	do i = 1 to 16;
		if any[i] = 1          then ipw[i] = num[i]/den[i]; 
			else if any[i] = 0 then ipw[i] = (1-num[i])/(1-den[i]);

		/* for unstabilized use this
		if any[i] = 1          then ipw[i] = 1/den[i]; 
			else if any[i] = 0 then ipw[i] = 1/(1-den[i]); */
	end;

	drop i _LEVEL_ n_MH n_str n_adhd n_anx n_dep  n_dev n_phb n_psy n_ptsd n_sex n_slp n_sub n_per n_crf n_NOS n_oth
				   d_MH d_str d_adhd d_anx d_dep  d_dev d_phb d_psy d_ptsd d_sex d_slp d_sub d_per d_crf d_NOS d_oth;
run;

proc datasets;
	delete MH_den str_den adhd_den anx_den dep_den dev_den phb_den psy_den ptsd_den sex_den slp_den sub_den per_den crf_den NOS_den oth_den
		   MH_num str_num adhd_num anx_num dep_num dev_num phb_num psy_num ptsd_num sex_num slp_num sub_num per_num crf_num NOS_num oth_num;
run;
quit;

* Create "complete" time data base collapsing across "months";
data medrec3;
	merge demog (in = inc) medrec2;
	by w19_1011_lnr_k2_;

	if inc;

	year_dx    = YEAR(DATO);
	quarter_dx = QTR(DATO);
	month_dx   = MONTH(DATO);
run;
proc freq data = medrec3 noprint;
	table year_dx*quarter_dx*month_dx / out = yr_qr_mo;
run;
data yr_qr_mo1;
	set yr_qr_mo;

	if year_dx = . then delete;

	retain yrqrmo (0);

	yrqrmo = yrqrmo + 1;

	drop COUNT PERCENT;
run;

proc transpose data = yr_qr_mo1 out = yr_qr_mo2; run;

data yr; set yr_qr_mo2; if _NAME_ = 'year_dx';    rename col1-col168 = yr1-yr168; drop _NAME_; run;
data qr; set yr_qr_mo2; if _NAME_ = 'quarter_dx'; rename col1-col168 = qr1-qr168; drop _NAME_; run;
data mo; set yr_qr_mo2; if _NAME_ = 'month_dx';   rename col1-col168 = mo1-mo168; drop _NAME_; run;
data tm; set yr_qr_mo2; if _NAME_ = 'yrqrmo';     rename col1-col168 = tm1-tm168; drop _NAME_; run;

data time;
	merge yr qr mo tm;
run;

proc sql;
	create table full_data as
	select *
	from insample, time;
quit;

data full_mo;
	set full_data;

	array yr [168]	yr1-yr168;	
	array qr [168]	qr1-qr168;
	array mo [168]	mo1-mo168;
	array tm [168]  tm1-tm168;

	do i = 1 to 168;
		year_dx    = yr[i];
		quarter_dx = qr[i];
		month_dx   = mo[i];
		time_dx    = tm[i];
		output;
	end;

	keep w19_1011_lnr_k2_ year_dx quarter_dx month_dx time_dx;
run;
data full_mo_death;
	merge full_mo demog (keep = w19_1011_lnr_k2_ DOD);
	by w19_1011_lnr_k2_;

	mdy_dx = MDY(month_dx, 1, year_dx);

	if DOD ne . and mdy_dx > DOD then delete;
run;

proc datasets; delete ids mo qr time tm yr yr_qr_mo yr_qr_mo1 yr_qr_mo2 full_data; run; quit;

* Save prepped data;
data mhinj.full_mo;
	set full_mo_death;
data mhinj.grp;
	set medrec_wide_ipw;
data mhinj.MHInj_Medrec;
	set medrec3;
run;

**************************************************;
* START HERE ... Once set up					  ;
**************************************************;

* Read in prepped data;
data full_mo;
	set mhinj.full_mo;
data grp;
	set mhinj.grp;
data medrec3;
	set mhinj.MHInj_Medrec;
run;

*******************************************************************;
* eAppendix4: Prevalences of Mental Health Disorders and Injuries  ;
*******************************************************************;
ods output OneWayFreqs = Prevalences;
proc freq data = grp;
	table	any_str any_adhd any_anx any_dep  any_dev /*any_eat*/ any_phb any_psy any_ptsd any_sex 
			any_slp /*any_som*/  any_sub /*any_chad any_con*/ any_per any_crf /*any_pha any_stu any_fmh
			any_irr*/ any_NOS  any_oth
			any_A /*any_B*/ any_D any_F any_H any_L any_N /*any_R*/ any_S /*any_U any_W any_X*/ any_O
			any_Ac any_Dc any_Fc any_Hc any_Lc any_Nc any_Sc any_Oc;
	table 	any_MH any_inj;
run;
ods output close;

proc sort data = Prevalences; by Table; run;
data Prevalences1;
	set Prevalences;
	by Table;

	retain dx;

	if first.Table then dx = 0;
		else if last.Table then dx = 1;

	if dx = 1;

	keep Table Frequency Percent CumFrequency;
run;

proc export data = Prevalences1
	outfile = "M:\p1074-renateh\2023_MHInjuries\MHInj_eAppendix4_Prev_05Apr2024.csv"
	dbms = csv
	replace;
run;

* How many have neither MH disorder nor injury?;
* N = 509,251 (18.5%);
* N = 1060294 (69.2%) of those with MH disorder (N = 1533109) had injury;
* N = 711286 (58.3%) of those without MH disorder (N = 1220537) had injury;
proc freq data = grp;
	table any_MH*any_inj;
run;

* How many males/females with/without mental health disorders?;
* N Males = 1406301 (51.1%), N Females = 1347345 (48.9%);
* N Males with MH dx = 674589 (48.0%), N Females with MH dx = 858520 (63.7%);
proc freq data = grp;
	table male;
	table male*any_MH;
run;

proc datasets; delete prevalences prevalences1; run; quit;

*******************************************;
* SET UP MACROS to PREP DATA for HR models ;
*******************************************;

* ID encounters with specific MH diagnoses;
%macro make_mh (MHfilter = , dx = );

	data &dx;
		set medrec3; 
			if &MHfilter;
	run;
	proc sort data = &dx nodupkey; 
		by w19_1011_lnr_k2_ year_dx quarter_dx month_dx; 
	run;
	data &dx; 
		set &dx; 
		MH = 1; 
		keep w19_1011_lnr_k2_ year_dx quarter_dx month_dx MH;
	run;
%mend make_mh;

* ID encounters with specific injury types;
%macro make_ph (PHfilter = , dx = );
	data &dx; 
		set medrec3; 
			if &PHfilter;
	run;
	proc sort data = &dx nodupkey;
		by w19_1011_lnr_k2_ year_dx quarter_dx month_dx;
	run;
	data &dx; 
		set &dx; 
		PH = 1; 
		keep w19_1011_lnr_k2_ year_dx quarter_dx month_dx PH; 
	run;
%mend make_ph;

%make_ph(PHfilter = injury =  1, dx = inj);
%make_ph(PHfilter = dx_all = 51, dx = A);
%make_ph(PHfilter = dx_all = 53, dx = D);
%make_ph(PHfilter = dx_all = 54, dx = F);
%make_ph(PHfilter = dx_all = 55, dx = H);
%make_ph(PHfilter = dx_all = 56, dx = L);
%make_ph(PHfilter = dx_all = 57, dx = N);
%make_ph(PHfilter = dx_all = 59, dx = S);

proc freq data = grp;
	table any_MH*Any_inj*(any_A any_D any_F any_H any_L any_N any_S) / list missing;
	where any_str = 0;
proc freq data = grp;
	table any_MH*Any_inj*(any_A any_D any_F any_H any_L any_N any_S) / list missing;
	where any_str = 1;
run;

* Prep for "previous injury control" by finding first observed injury;
proc sort data = inj out = first_inj nodupkey; by w19_1011_lnr_k2_; run;

data first_inj;
	merge full_mo first_inj;
	by w19_1011_lnr_k2_ year_dx quarter_dx month_dx;

	if PH = 1;

	first_inj = time_dx;
	keep w19_1011_lnr_k2_ first_inj;
run;

* Prep files for recurrent events with time varying covariates HRs;
%macro combine_MHPH (MHdx = , PHdx = , ipw = );

	* Merge full time dataset with MH & PH files;
	data &MHdx._&PHdx;
		merge full_mo (in = infull) &MHdx &PHdx;
		by w19_1011_lnr_k2_ year_dx quarter_dx month_dx;

		if infull;

		if MH = . then MH = 0;
		if PH = . then PH = 0;
	run;

	* Flip to wide file with indicators for whether there were encounters for MH/PH each month;
	data &MHdx._&PHdx._wide;
		array mht [168]	mh1-mh168;
		array pht [168]	ph1-ph168;

		do i = 1 to 168 until (last.w19_1011_lnr_k2_);
			set &MHdx._&PHdx;
			by w19_1011_lnr_k2_;

			mht[i] = MH;
			pht[i] = PH;
		end;
		drop i MH PH year_dx quarter_dx month_dx;
	run;

	* Merge in IPWs and timing of first injury;
	* Set clean comparison group;
	data &MHdx._&PHdx._wide;
		merge grp &MHdx._&PHdx._wide first_inj;
		by w19_1011_lnr_k2_;

		* Create clean comparison group;
		if any_&MHdx = 0 and any_MH  = 1 then delete; * Clean MH comparison;
		*if any_&PHdx = 0 and any_inj = 1 then delete; * Clean Injury comparison;

		array ph [168]	ph1--ph168;

		* Find timing of first injury of selected type and timing of death;
		do i = 1 to 168;
			if i = 1 then first_ph = .;
			if ph[i] = 1 and first_ph = . then first_ph = i;

			if i = 1 then death = .;
			if ph[i] = . and death = . then death = i-1;
		end;

		* Set censoring type (censored, injury, death);
		if first_ph = . and death = . then censor = 0;
			else if first_ph ne . and death = . then censor = 1;
			else if first_ph = . and death ne . then censor = 2;

		* Set time of first dx or death;
		time = min(first_ph, death);
		if first_ph = . and death = . then time = 168;

		keep w19_1011_lnr_k2_ male county age_start education any_&MHdx any_inj any_&PHdx mh1-mh168 ph1-ph168 &ipw censor time first_ph first_inj death age_band;
	run;

	proc datasets; delete &MHdx._&PHdx; run; quit;

	* Following code adapted from:
	* 	Powell, TM & Bagnell, ME. (2012). Your "survival" guide to using time-dependent covariates. SAS Global Forum 2012, p. 168-2012.;

	* Create indicator for when there is a change in PH or MH dx;
	data change;
		set &MHdx._&PHdx._wide;

		array mh [168] mh1-mh168;
		array ph [168] ph1-ph168;
		array chg [167];

		t = 1;
		do i = 2 to 168;
			if (mh[i] NE mh[i-1]) OR (ph[i] NE ph[i-1]) then do;
				chg[t] = i-1;
				t = t + 1;
			end;
		end;
		chg168 = .;
		drop t i;
	run;

	* Create long file ready for start/stop coding in PHREG;
	data &MHdx._&PHdx._rec (drop = mh1-mh168 ph1-ph168 chg1-chg168 t i);
		set change;

		array mh  [168] mh1-mh168;
		array ph  [168] ph1-ph168;
		array chg [168] chg1-chg168;

		start   = 0;
		t       = 1;

		do i = 1 to 168;
			if chg[t] > . and chg[t] < 168 or i = 168 then do;
				if chg[t] > . then tvmh = mh[chg[t]];
				else tvmh = mh[168];

				if chg[t] > . then tvph = ph[chg[t]];
				else tvph = ph[168];

				stop = min(chg[t], death, 168);

				if t > 1 then start = chg[t-1];

				t = t + 1;
				output;
			end;
		end;
	run;

	* Merge first injury in and code whether there was a previous injury for each record;
	data &MHdx._&PHdx._rec;
		merge &MHdx._&PHdx._rec first_inj;
		by w19_1011_lnr_k2_;

		if first_inj = . or stop <= first_inj then prev_inj = 0;
			else if stop > first_inj then prev_inj = 1;

		if first_ph = . or stop <= first_ph then prev_ph = 0;
			else if stop > first_ph then prev_ph = 1;

		if start = stop and tvmh = . and tvph = . then delete;

		* Competing risk for death;
		if death = stop then tvph = 2;
	run;

	proc datasets; delete change &MHdx._&PHdx._wide; run; quit;
%mend combine_MHPH;

%macro run_recurr(ds = , MHvar = , PHvar = , ipw = );

	proc phreg data = &ds;
		model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
		weight &ipw;		
		ods output ParameterEstimates = ModelEsts3;
	run;
	data ModelEsts3;
		set ModelEsts3;
		length MHvar $ 20;
		length PHvar $ 20;

		MHvar = &MHvar;
		PHvar = &PHvar;
	run;
	proc datasets;
		append base = PrevInj data = ModelEsts3;
	run;
	quit;

%mend run_recurr;

* Any Mental Health Dx;
%make_mh(MHfilter = anyMH  =  1, dx = MH);

%combine_MHPH(MHdx = MH, PHdx = inj, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = A, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = D, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = F, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = H, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = L, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = N, ipw = MH_ipw);
%combine_MHPH(MHdx = MH, PHdx = S, ipw = MH_ipw);

/*
* Cox cause-specific hazards;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = tvmh / ties = efron rl;
	weight MH_ipw;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,1) = tvmh / ties = efron rl;
	weight MH_ipw;
run;
* Fine-Gray subdistribution hazards;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0) = tvmh / ties = efron rl eventcode = 1;
	weight MH_ipw;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0) = tvmh / ties = efron rl eventcode = 2;
	weight MH_ipw;
run;
*/

****************************************;
* Subgroup analyses: eAppendix 13       ;
****************************************;
* Everyone;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	ods output ParameterEstimates = All_est;
data All_est;
	set All_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "All";
run;

* Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where male = 1;
	ods output ParameterEstimates = M_est;
data M_est;
	set M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "All";
run;
* Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where male = 0;
	ods output ParameterEstimates = F_est;
data F_est;
	set F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "All";
run;

* Age 10-20;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 10;
	ods output ParameterEstimates = age10_est;
data Age10_est;
	set Age10_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "[10-20)";
run;
* Ages 20-30;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 20;
	ods output ParameterEstimates = age20_est;
data Age20_est;
	set age20_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "[20-30)";
run;
* Age 30-40;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 30;
	ods output ParameterEstimates = age30_est;
data Age30_est;
	set Age30_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "[30-40)";
run;
* Ages 40-50;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 40;
	ods output ParameterEstimates = age40_est;
data Age40_est;
	set age40_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "[40-50)";
run;
* Ages 50-60;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 50;
	ods output ParameterEstimates = age50_est;
data Age50_est;
	set age50_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Both";
	Age   = "[50-60]";
run;

* Age 10-20, Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 10 and male = 1;
	ods output ParameterEstimates = age10M_est;
data Age10M_est;
	set Age10M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "[10-20)";
run;
* Age 10-20, Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 10 and male = 0;
	ods output ParameterEstimates = age10F_est;
data Age10F_est;
	set Age10F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "[10-20)";
run;
* Ages 20-30, Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 20 and male = 1;
	ods output ParameterEstimates = age20M_est;
data Age20M_est;
	set age20M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "[20-30)";
run;
* Ages 20-30, Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 20 and male = 0;
	ods output ParameterEstimates = age20F_est;
data Age20F_est;
	set age20F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "[20-30)";
run;
* Age 30-40, Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 30 and male = 1;
	ods output ParameterEstimates = age30M_est;
data Age30M_est;
	set Age30M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "[30-40)";
run;
* Age 30-40, Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;
	where age_band = 30 and male = 0;
	ods output ParameterEstimates = age30F_est;
data Age30F_est;
	set Age30F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "[30-40)";
run;
* Ages 40-50, Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 40 and male = 1;
	ods output ParameterEstimates = age40M_est;
data Age40M_est;
	set age40M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "[40-50)";
run;
* Ages 40-50, Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 40 and male = 0;
	ods output ParameterEstimates = age40F_est;
data Age40F_est;
	set age40F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "[40-50)";
run;

* Ages 50-60, Males;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 50 and male = 1;
	ods output ParameterEstimates = age50M_est;
data Age50M_est;
	set age50M_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Male";
	Age   = "[50-60]";
run;
* Ages 50-60, Females;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	where age_band = 50 and male = 0;
	ods output ParameterEstimates = age50F_est;
data Age50F_est;
	set age50F_est;
	length MHvar $ 40;
	length PHvar $ 20;
	length Sex   $ 6;
	length Age   $ 7;

	MHvar = "MH";
	PHvar = "Injury";
	Sex   = "Female";
	Age   = "[50-60]";
run;

 * Combine and export;
data eAppendix13;
	set All_est M_est F_est 
		Age10_est  Age20_est  Age30_est  Age40_est  Age50_est
		Age10M_est Age20M_est Age30M_est Age40M_est Age50M_est
		Age10F_est Age20F_est Age30F_est Age40F_est Age50F_est;

	if parameter = "tvmh";
run;

proc export data = eAppendix13
	outfile = "M:\p1074-renateh\2023_MHInjuries\MHInj_eAppendix13_GrpHRs_03Apr2024_CleanMH.csv"
	dbms = csv
	replace;
run;

proc datasets;
	delete All_est M_est F_est 
			Age10_est  Age20_est  Age30_est  Age40_est  Age50_est
			Age10M_est Age20M_est Age30M_est Age40M_est Age50M_est
			Age10F_est Age20F_est Age30F_est Age40F_est Age50F_est;
run;
quit;

**********************;
* Figure 4 Estimates  ;
**********************;

* Any Mental Health;
proc phreg data = MH_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight MH_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "MH";
	PHvar = "Injury";
run;

%run_recurr(ds = MH_A_rec, MHvar = "MH", PHvar = "A: General",         ipw = MH_ipw);
%run_recurr(ds = MH_D_rec, MHvar = "MH", PHvar = "D: Digestive",       ipw = MH_ipw);
%run_recurr(ds = MH_F_rec, MHvar = "MH", PHvar = "F: Eye",             ipw = MH_ipw);
%run_recurr(ds = MH_H_rec, MHvar = "MH", PHvar = "H: Ear",             ipw = MH_ipw);
%run_recurr(ds = MH_L_rec, MHvar = "MH", PHvar = "L: Musculoskeletal", ipw = MH_ipw);
%run_recurr(ds = MH_N_rec, MHvar = "MH", PHvar = "N: Neurological",    ipw = MH_ipw);
%run_recurr(ds = MH_S_rec, MHvar = "MH", PHvar = "S: Skin",            ipw = MH_ipw);

data mhinj.MH_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj; run; quit;

* Acute Stress;
%make_mh(MHfilter = dx_all =  1, dx = Str);

%combine_MHPH(MHdx = Str, PHdx = inj, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = A, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = D, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = F, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = H, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = L, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = N, ipw = Str_ipw);
%combine_MHPH(MHdx = Str, PHdx = S, ipw = Str_ipw);

proc phreg data = Str_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Str_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Acute Stress";
	PHvar = "Injury";
run;

%run_recurr(ds = Str_A_rec, MHvar = "Acute Stress", PHvar = "A: General",         ipw = Str_ipw);
%run_recurr(ds = Str_D_rec, MHvar = "Acute Stress", PHvar = "D: Digestive",       ipw = Str_ipw);
%run_recurr(ds = Str_F_rec, MHvar = "Acute Stress", PHvar = "F: Eye",             ipw = Str_ipw);
%run_recurr(ds = Str_H_rec, MHvar = "Acute Stress", PHvar = "H: Ear",             ipw = Str_ipw);
%run_recurr(ds = Str_L_rec, MHvar = "Acute Stress", PHvar = "L: Musculoskeletal", ipw = Str_ipw);
%run_recurr(ds = Str_N_rec, MHvar = "Acute Stress", PHvar = "N: Neurological",    ipw = Str_ipw);
%run_recurr(ds = Str_S_rec, MHvar = "Acute Stress", PHvar = "S: Skin",            ipw = Str_ipw);

data mhinj.Str_HRs_PrevInj; set PrevInj; run; 

proc datasets; delete PrevInj Str_A_rec Str_D_rec Str_F_rec Str_H_rec Str_L_rec Str_N_rec Str_S_rec; run; quit;

* ADHD;
%make_mh(MHfilter = dx_all =  2, dx = ADHD);

%combine_MHPH(MHdx = ADHD, PHdx = inj, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = A, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = D, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = F, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = H, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = L, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = N, ipw = ADHD_ipw);
%combine_MHPH(MHdx = ADHD, PHdx = S, ipw = ADHD_ipw);

proc phreg data = ADHD_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight ADHD_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "ADHD";
	PHvar = "Injury";
run;

%run_recurr(ds = ADHD_A_rec, MHvar = "ADHD", PHvar = "A: General",         ipw = ADHD_ipw);
%run_recurr(ds = ADHD_D_rec, MHvar = "ADHD", PHvar = "D: Digestive",       ipw = ADHD_ipw);
%run_recurr(ds = ADHD_F_rec, MHvar = "ADHD", PHvar = "F: Eye",             ipw = ADHD_ipw);
%run_recurr(ds = ADHD_H_rec, MHvar = "ADHD", PHvar = "H: Ear",             ipw = ADHD_ipw);
%run_recurr(ds = ADHD_L_rec, MHvar = "ADHD", PHvar = "L: Musculoskeletal", ipw = ADHD_ipw);
%run_recurr(ds = ADHD_N_rec, MHvar = "ADHD", PHvar = "N: Neurological",    ipw = ADHD_ipw);
%run_recurr(ds = ADHD_S_rec, MHvar = "ADHD", PHvar = "S: Skin",            ipw = ADHD_ipw);

data mhinj.ADHD_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj ADHD_A_rec ADHD_D_rec ADHD_F_rec ADHD_H_rec ADHD_L_rec ADHD_N_rec ADHD_S_rec; run; quit;

* Anxiety;
%make_mh(MHfilter = dx_all =  3, dx = Anx);

%combine_MHPH(MHdx = Anx, PHdx = inj, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = A, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = D, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = F, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = H, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = L, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = N, ipw = Anx_ipw);
%combine_MHPH(MHdx = Anx, PHdx = S, ipw = Anx_ipw);

proc phreg data = Anx_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Anx_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Anxiety";
	PHvar = "Injury";
run;

%run_recurr(ds = Anx_A_rec, MHvar = "Anxiety", PHvar = "A: General",         ipw = Anx_ipw);
%run_recurr(ds = Anx_D_rec, MHvar = "Anxiety", PHvar = "D: Digestive",       ipw = Anx_ipw);
%run_recurr(ds = Anx_F_rec, MHvar = "Anxiety", PHvar = "F: Eye",             ipw = Anx_ipw);
%run_recurr(ds = Anx_H_rec, MHvar = "Anxiety", PHvar = "H: Ear",             ipw = Anx_ipw);
%run_recurr(ds = Anx_L_rec, MHvar = "Anxiety", PHvar = "L: Musculoskeletal", ipw = Anx_ipw);
%run_recurr(ds = Anx_N_rec, MHvar = "Anxiety", PHvar = "N: Neurological",    ipw = Anx_ipw);
%run_recurr(ds = Anx_S_rec, MHvar = "Anxiety", PHvar = "S: Skin",            ipw = Anx_ipw);

data mhinj.Anx_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj Anx_A_rec Anx_D_rec Anx_F_rec Anx_H_rec Anx_L_rec Anx_N_rec Anx_S_rec; run; quit;

* Depression;
%make_mh(MHfilter = dx_all =  5, dx = Dep);

%combine_MHPH(MHdx = Dep, PHdx = inj, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = A, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = D, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = F, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = H, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = L, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = N, ipw = Dep_ipw);
%combine_MHPH(MHdx = Dep, PHdx = S, ipw = Dep_ipw);

proc phreg data = Dep_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Dep_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Depression";
	PHvar = "Injury";
run;

%run_recurr(ds = Dep_A_rec, MHvar = "Depression", PHvar = "A: General",         ipw = Dep_ipw);
%run_recurr(ds = Dep_D_rec, MHvar = "Depression", PHvar = "D: Digestive",       ipw = Dep_ipw);
%run_recurr(ds = Dep_F_rec, MHvar = "Depression", PHvar = "F: Eye",             ipw = Dep_ipw);
%run_recurr(ds = Dep_H_rec, MHvar = "Depression", PHvar = "H: Ear",             ipw = Dep_ipw);
%run_recurr(ds = Dep_L_rec, MHvar = "Depression", PHvar = "L: Musculoskeletal", ipw = Dep_ipw);
%run_recurr(ds = Dep_N_rec, MHvar = "Depression", PHvar = "N: Neurological",    ipw = Dep_ipw);
%run_recurr(ds = Dep_S_rec, MHvar = "Depression", PHvar = "S: Skin",            ipw = Dep_ipw);

data mhinj.Dep_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj Dep_A_rec Dep_D_rec Dep_F_rec Dep_H_rec Dep_L_rec Dep_N_rec Dep_S_rec; run; quit;

* Developmental Delay;
%make_mh(MHfilter = dx_all =  6, dx = Dev);

%combine_MHPH(MHdx = Dev, PHdx = inj, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = A, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = D, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = F, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = H, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = L, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = N, ipw = Dev_ipw);
%combine_MHPH(MHdx = Dev, PHdx = S, ipw = Dev_ipw);

%recurrent(MHdx = Dev, PHdx = inj);
%recurrent(MHdx = Dev, PHdx = A);
%recurrent(MHdx = Dev, PHdx = D);
%recurrent(MHdx = Dev, PHdx = F);
%recurrent(MHdx = Dev, PHdx = H);
%recurrent(MHdx = Dev, PHdx = L);
%recurrent(MHdx = Dev, PHdx = N);
%recurrent(MHdx = Dev, PHdx = S);

proc phreg data = Dev_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Dev_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Developmental Delay";
	PHvar = "Injury";
run;

%run_recurr(ds = Dev_A_rec, MHvar = "Developmental Delay", PHvar = "A: General",         ipw = Dev_ipw);
%run_recurr(ds = Dev_D_rec, MHvar = "Developmental Delay", PHvar = "D: Digestive",       ipw = Dev_ipw);
%run_recurr(ds = Dev_F_rec, MHvar = "Developmental Delay", PHvar = "F: Eye",             ipw = Dev_ipw);
%run_recurr(ds = Dev_H_rec, MHvar = "Developmental Delay", PHvar = "H: Ear",             ipw = Dev_ipw);
%run_recurr(ds = Dev_L_rec, MHvar = "Developmental Delay", PHvar = "L: Musculoskeletal", ipw = Dev_ipw);
%run_recurr(ds = Dev_N_rec, MHvar = "Developmental Delay", PHvar = "N: Neurological",    ipw = Dev_ipw);
%run_recurr(ds = Dev_S_rec, MHvar = "Developmental Delay", PHvar = "S: Skin",            ipw = Dev_ipw);

data mhinj.Dev_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj Dev_A_rec Dev_D_rec Dev_F_rec Dev_H_rec Dev_L_rec Dev_N_rec Dev_S_rec; run; quit;

* Phobia;
%make_mh(MHfilter = dx_all =  8, dx = Phb);

%combine_MHPH(MHdx = Phb, PHdx = inj, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = A, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = D, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = F, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = H, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = L, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = N, ipw = Phb_ipw);
%combine_MHPH(MHdx = Phb, PHdx = S, ipw = Phb_ipw);

proc phreg data = Phb_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Phb_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Phobia";
	PHvar = "Injury";
run;

%run_recurr(ds = Phb_A_rec, MHvar = "Phobia", PHvar = "A: General",         ipw = Phb_ipw);
%run_recurr(ds = Phb_D_rec, MHvar = "Phobia", PHvar = "D: Digestive",       ipw = Phb_ipw);
%run_recurr(ds = Phb_F_rec, MHvar = "Phobia", PHvar = "F: Eye",             ipw = Phb_ipw);
%run_recurr(ds = Phb_H_rec, MHvar = "Phobia", PHvar = "H: Ear",             ipw = Phb_ipw);
%run_recurr(ds = Phb_L_rec, MHvar = "Phobia", PHvar = "L: Musculoskeletal", ipw = Phb_ipw);
%run_recurr(ds = Phb_N_rec, MHvar = "Phobia", PHvar = "N: Neurological",    ipw = Phb_ipw);
%run_recurr(ds = Phb_S_rec, MHvar = "Phobia", PHvar = "S: Skin",            ipw = Phb_ipw);

data mhinj.Phb_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj Phb_A_rec Phb_D_rec Phb_F_rec Phb_H_rec Phb_L_rec Phb_N_rec Phb_S_rec; run; quit;

* Psychosis;
%make_mh(MHfilter = dx_all =  9, dx = Psy);

%combine_MHPH(MHdx = Psy, PHdx = inj, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = A, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = D, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = F, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = H, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = L, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = N, ipw = Psy_ipw);
%combine_MHPH(MHdx = Psy, PHdx = S, ipw = Psy_ipw);

proc phreg data = Psy_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Psy_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Psychosis";
	PHvar = "Injury";
run;

%run_recurr(ds = Psy_A_rec, MHvar = "Psychosis", PHvar = "A: General",         ipw = Psy_ipw);
%run_recurr(ds = Psy_D_rec, MHvar = "Psychosis", PHvar = "D: Digestive",       ipw = Psy_ipw);
%run_recurr(ds = Psy_F_rec, MHvar = "Psychosis", PHvar = "F: Eye",             ipw = Psy_ipw);
%run_recurr(ds = Psy_H_rec, MHvar = "Psychosis", PHvar = "H: Ear",             ipw = Psy_ipw);
%run_recurr(ds = Psy_L_rec, MHvar = "Psychosis", PHvar = "L: Musculoskeletal", ipw = Psy_ipw);
%run_recurr(ds = Psy_N_rec, MHvar = "Psychosis", PHvar = "N: Neurological",    ipw = Psy_ipw);
%run_recurr(ds = Psy_S_rec, MHvar = "Psychosis", PHvar = "S: Skin",            ipw = Psy_ipw);

data mhinj.Psy_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj Psy_A_rec Psy_D_rec Psy_F_rec Psy_H_rec Psy_L_rec Psy_N_rec Psy_S_rec; run; quit;

* PTSD;
%make_mh(MHfilter = dx_all = 10, dx = PTSD);

%combine_MHPH(MHdx = PTSD, PHdx = inj, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = A, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = D, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = F, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = H, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = L, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = N, ipw = PTSD_ipw);
%combine_MHPH(MHdx = PTSD, PHdx = S, ipw = PTSD_ipw);

proc phreg data = PTSD_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight PTSD_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "PTSD";
	PHvar = "Injury";
run;

%run_recurr(ds = PTSD_A_rec, MHvar = "PTSD", PHvar = "A: General",         ipw = PTSD_ipw);
%run_recurr(ds = PTSD_D_rec, MHvar = "PTSD", PHvar = "D: Digestive",       ipw = PTSD_ipw);
%run_recurr(ds = PTSD_F_rec, MHvar = "PTSD", PHvar = "F: Eye",             ipw = PTSD_ipw);
%run_recurr(ds = PTSD_H_rec, MHvar = "PTSD", PHvar = "H: Ear",             ipw = PTSD_ipw);
%run_recurr(ds = PTSD_L_rec, MHvar = "PTSD", PHvar = "L: Musculoskeletal", ipw = PTSD_ipw);
%run_recurr(ds = PTSD_N_rec, MHvar = "PTSD", PHvar = "N: Neurological",    ipw = PTSD_ipw);
%run_recurr(ds = PTSD_S_rec, MHvar = "PTSD", PHvar = "S: Skin",            ipw = PTSD_ipw);

data mhinj.PTSD_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj PTSD_A_rec PTSD_D_rec PTSD_F_rec PTSD_H_rec PTSD_L_rec PTSD_N_rec PTSD_S_rec; run; quit;

* Sleep Disturbance;
%make_mh(MHfilter = dx_all = 12, dx = Slp);

%combine_MHPH(MHdx = Slp, PHdx = inj, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = A, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = D, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = F, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = H, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = L, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = N, ipw = Slp_ipw);
%combine_MHPH(MHdx = Slp, PHdx = S, ipw = Slp_ipw);

proc phreg data = Slp_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Slp_ipw;
	ods output ParameterEstimates = ModelEsts3;
run;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Sleep Disturbance";
	PHvar = "Injury";
run;

%run_recurr(ds = Slp_A_rec, MHvar = "Sleep Disturbance", PHvar = "A: General",         ipw = Slp_ipw);
%run_recurr(ds = Slp_D_rec, MHvar = "Sleep Disturbance", PHvar = "D: Digestive",       ipw = Slp_ipw);
%run_recurr(ds = Slp_F_rec, MHvar = "Sleep Disturbance", PHvar = "F: Eye",             ipw = Slp_ipw);
%run_recurr(ds = Slp_H_rec, MHvar = "Sleep Disturbance", PHvar = "H: Ear",             ipw = Slp_ipw);
%run_recurr(ds = Slp_L_rec, MHvar = "Sleep Disturbance", PHvar = "L: Musculoskeletal", ipw = Slp_ipw);
%run_recurr(ds = Slp_N_rec, MHvar = "Sleep Disturbance", PHvar = "N: Neurological",    ipw = Slp_ipw);
%run_recurr(ds = Slp_S_rec, MHvar = "Sleep Disturbance", PHvar = "S: Skin",            ipw = Slp_ipw);

data mhinj.Slp_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj Slp_A_rec Slp_D_rec Slp_F_rec Slp_H_rec Slp_L_rec Slp_N_rec Slp_S_rec; run; quit;

* Sexual Concern;
%make_mh(MHfilter = dx_all = 11, dx = Sex);

%combine_MHPH(MHdx = Sex, PHdx = inj, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = A, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = D, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = F, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = H, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = L, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = N, ipw = Sex_ipw);
%combine_MHPH(MHdx = Sex, PHdx = S, ipw = Sex_ipw);

proc phreg data = Sex_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Sex_ipw;	
	ods output ParameterEstimates = ModelEsts3;
run;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Sexual Concern";
	PHvar = "Injury";
run;

%run_recurr(ds = Sex_A_rec, MHvar = "Sexual Concern", PHvar = "A: General",         ipw = Sex_ipw);
%run_recurr(ds = Sex_D_rec, MHvar = "Sexual Concern", PHvar = "D: Digestive",       ipw = Sex_ipw);
%run_recurr(ds = Sex_F_rec, MHvar = "Sexual Concern", PHvar = "F: Eye",             ipw = Sex_ipw);
%run_recurr(ds = Sex_H_rec, MHvar = "Sexual Concern", PHvar = "H: Ear",             ipw = Sex_ipw);
%run_recurr(ds = Sex_L_rec, MHvar = "Sexual Concern", PHvar = "L: Musculoskeletal", ipw = Sex_ipw);
%run_recurr(ds = Sex_N_rec, MHvar = "Sexual Concern", PHvar = "N: Neurological",    ipw = Sex_ipw);
%run_recurr(ds = Sex_S_rec, MHvar = "Sexual Concern", PHvar = "S: Skin",            ipw = Sex_ipw);

data mhinj.Sex_HRs_PrevInj; set PrevInj; run;

proc datasets; delete PrevInj Sex_A_rec Sex_D_rec Sex_F_rec Sex_H_rec Sex_L_rec Sex_N_rec Sex_S_rec; run; quit;

* Substance Abuse;
%make_mh(MHfilter = dx_all = 14, dx = Sub);

%combine_MHPH(MHdx = Sub, PHdx = inj, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = A, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = D, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = F, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = H, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = L, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = N, ipw = Sub_ipw);
%combine_MHPH(MHdx = Sub, PHdx = S, ipw = Sub_ipw);

proc phreg data = Sub_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Sub_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Substance Abuse";
	PHvar = "Injury";
run;

%run_recurr(ds = Sub_A_rec, MHvar = "Substance Abuse", PHvar = "A: General",         ipw = Sub_ipw);
%run_recurr(ds = Sub_D_rec, MHvar = "Substance Abuse", PHvar = "D: Digestive",       ipw = Sub_ipw);
%run_recurr(ds = Sub_F_rec, MHvar = "Substance Abuse", PHvar = "F: Eye",             ipw = Sub_ipw);
%run_recurr(ds = Sub_H_rec, MHvar = "Substance Abuse", PHvar = "H: Ear",             ipw = Sub_ipw);
%run_recurr(ds = Sub_L_rec, MHvar = "Substance Abuse", PHvar = "L: Musculoskeletal", ipw = Sub_ipw);
%run_recurr(ds = Sub_N_rec, MHvar = "Substance Abuse", PHvar = "N: Neurological",    ipw = Sub_ipw);
%run_recurr(ds = Sub_S_rec, MHvar = "Substance Abuse", PHvar = "S: Skin",            ipw = Sub_ipw);

data mhinj.Sub_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj Sub_A_rec Sub_D_rec Sub_F_rec Sub_H_rec Sub_L_rec Sub_N_rec Sub_S_rec; run; quit;

* Personality Disorder;
%make_mh(MHfilter = dx_all = 18, dx = Per);

%combine_MHPH(MHdx = Per, PHdx = inj, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = A, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = D, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = F, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = H, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = L, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = N, ipw = Per_ipw);
%combine_MHPH(MHdx = Per, PHdx = S, ipw = Per_ipw);

proc phreg data = Per_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight Per_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Personality Disorder";
	PHvar = "Injury";
run;

%run_recurr(ds = Per_A_rec, MHvar = "Personality Disorder", PHvar = "A: General",         ipw = Per_ipw);
%run_recurr(ds = Per_D_rec, MHvar = "Personality Disorder", PHvar = "D: Digestive",       ipw = Per_ipw);
%run_recurr(ds = Per_F_rec, MHvar = "Personality Disorder", PHvar = "F: Eye",             ipw = Per_ipw);
%run_recurr(ds = Per_H_rec, MHvar = "Personality Disorder", PHvar = "H: Ear",             ipw = Per_ipw);
%run_recurr(ds = Per_L_rec, MHvar = "Personality Disorder", PHvar = "L: Musculoskeletal", ipw = Per_ipw);
%run_recurr(ds = Per_N_rec, MHvar = "Personality Disorder", PHvar = "N: Neurological",    ipw = Per_ipw);
%run_recurr(ds = Per_S_rec, MHvar = "Personality Disorder", PHvar = "S: Skin",            ipw = Per_ipw);

data mhinj.Per_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj Per_A_rec Per_D_rec Per_F_rec Per_H_rec Per_L_rec Per_N_rec Per_S_rec; run; quit;

* NOS;
%make_mh(MHfilter = dx_all = 24, dx = NOS);

%combine_MHPH(MHdx = NOS, PHdx = inj, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = A, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = D, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = F, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = H, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = L, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = N, ipw = NOS_ipw);
%combine_MHPH(MHdx = NOS, PHdx = S, ipw = NOS_ipw);

proc phreg data = NOS_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight NOS_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Psychological symptom/disorder, NOS";
	PHvar = "Injury";
run;

%run_recurr(ds = NOS_A_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "A: General",         ipw = NOS_ipw);
%run_recurr(ds = NOS_D_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "D: Digestive",       ipw = NOS_ipw);
%run_recurr(ds = NOS_F_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "F: Eye",             ipw = NOS_ipw);
%run_recurr(ds = NOS_H_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "H: Ear",             ipw = NOS_ipw);
%run_recurr(ds = NOS_L_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "L: Musculoskeletal", ipw = NOS_ipw);
%run_recurr(ds = NOS_N_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "N: Neurological",    ipw = NOS_ipw);
%run_recurr(ds = NOS_S_rec, MHvar = "Psychological symptom/disorder, NOS", PHvar = "S: Skin",            ipw = NOS_ipw);

data mhinj.NOS_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj NOS_A_rec NOS_D_rec NOS_F_rec NOS_H_rec NOS_L_rec NOS_N_rec NOS_S_rec; run; quit;

* Chronic Fatigue;
%make_mh(MHfilter = dx_all = 19, dx = crf);

%combine_MHPH(MHdx = crf, PHdx = inj, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = A, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = D, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = F, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = H, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = L, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = N, ipw = crf_ipw);
%combine_MHPH(MHdx = crf, PHdx = S, ipw = crf_ipw);

proc phreg data = crf_inj_rec;
	model (start, stop)*tvph(0,2) = prev_inj tvmh / ties = efron rl;
	weight crf_ipw;	
	ods output ParameterEstimates = ModelEsts3;
data PrevInj;
	set ModelEsts3;
	length MHvar $ 40;
	length PHvar $ 20;

	MHvar = "Chronic fatigue";
	PHvar = "Injury";
run;

%run_recurr(ds = crf_A_rec, MHvar = "Chronic fatigue", PHvar = "A: General",         ipw = crf_ipw);
%run_recurr(ds = crf_D_rec, MHvar = "Chronic fatigue", PHvar = "D: Digestive",       ipw = crf_ipw);
%run_recurr(ds = crf_F_rec, MHvar = "Chronic fatigue", PHvar = "F: Eye",             ipw = crf_ipw);
%run_recurr(ds = crf_H_rec, MHvar = "Chronic fatigue", PHvar = "H: Ear",             ipw = crf_ipw);
%run_recurr(ds = crf_L_rec, MHvar = "Chronic fatigue", PHvar = "L: Musculoskeletal", ipw = crf_ipw);
%run_recurr(ds = crf_N_rec, MHvar = "Chronic fatigue", PHvar = "N: Neurological",    ipw = crf_ipw);
%run_recurr(ds = crf_S_rec, MHvar = "Chronic fatigue", PHvar = "S: Skin",            ipw = crf_ipw);

data mhinj.crf_HRs_PrevInj;	set PrevInj; run;

proc datasets; delete PrevInj crf_A_rec crf_D_rec crf_F_rec crf_H_rec crf_L_rec crf_N_rec crf_S_rec; run; quit;

* Combine files;
data mhinj.PrevInj;
	set mhinj.MH_HRs_PrevInj
		mhinj.str_HRs_PrevInj
		mhinj.adhd_HRs_PrevInj 
		mhinj.anx_HRs_PrevInj
		mhinj.dep_HRs_PrevInj 
		mhinj.dev_HRs_PrevInj 
		mhinj.phb_HRs_PrevInj 
		mhinj.psy_HRs_PrevInj 
		mhinj.ptsd_HRs_PrevInj
		mhinj.sex_HRs_PrevInj
		mhinj.slp_HRs_PrevInj 
		mhinj.sub_HRs_PrevInj 
		mhinj.per_HRs_PrevInj
		mhinj.NOS_HRs_PrevInj
		mhinj.crf_HRs_PrevInj;
run;

proc export data = mhinj.PrevInj
	outfile = "M:\p1074-renateh\2023_MHInjuries\MHInj_Figure4_HRs_03Apr2024_CleanMH.csv"
	dbms = csv
	replace;
run;

proc datasets; 
	delete	mhinj.MH_HRs_PrevInj  mhinj.str_HRs_PrevInj mhinj.adhd_HRs_PrevInj mhinj.anx_HRs_PrevInj  mhinj.dep_HRs_PrevInj 
			mhinj.dev_HRs_PrevInj mhinj.phb_HRs_PrevInj mhinj.psy_HRs_PrevInj  mhinj.ptsd_HRs_PrevInj mhinj.sex_HRs_PrevInj
			mhinj.slp_HRs_PrevInj mhinj.sub_HRs_PrevInj mhinj.per_HRs_PrevInj  mhinj.NOS_HRs_PrevInj  mhinj.crf_HRs_PrevInj;
run;
quit;

*************************************************;
* Figure 3. Risk / Risk Differences differences  ;
*************************************************;

* Find first observed MH dx;
%macro find_first(MH = ); 
	proc sort data = &MH   out = first_&MH   nodupkey; by w19_1011_lnr_k2_; run;

	data first_&MH;
		merge full_mo first_&MH;
		by w19_1011_lnr_k2_ year_dx quarter_dx month_dx;

		if MH = 1;

		first_&MH = time_dx;
		keep w19_1011_lnr_k2_ first_&MH;
	run;
%mend find_first;

%find_first(MH = MH);
%find_first(MH = ADHD);
%find_first(MH = Anx);
%find_first(MH = crf);
%find_first(MH = Dep);
%find_first(MH = Dev);
%find_first(MH = NOS);
%find_first(MH = Per);
%find_first(MH = Phb);
%find_first(MH = Psy);
%find_first(MH = PTSD);
%find_first(MH = Sex);
%find_first(MH = Slp);
%find_first(MH = Str);
%find_first(MH = Sub);

data risk;
	merge full_mo (in = infull) inj;
	by w19_1011_lnr_k2_ year_dx quarter_dx month_dx;

	if infull;

	if PH = 1 then injury = 1;
		else injury = 0;
run;
data risk;
	merge risk first_MH first_ADHD first_anx first_crf first_dep first_dev first_NOS first_per first_phb first_psy first_ptsd first_sex first_slp first_str first_sub
		  grp(keep = w19_1011_lnr_k2_ MH_ipw str_ipw adhd_ipw anx_ipw crf_ipw dep_ipw dev_ipw per_ipw phb_ipw psy_ipw ptsd_ipw
					 sex_ipw slp_ipw sub_ipw NOS_ipw
					 any_MH any_str any_adhd any_anx any_crf any_dep any_dev any_per any_phb any_psy any_ptsd any_sex any_slp any_sub any_NOS);
	by w19_1011_lnr_k2_;

	array first [15] first_MH first_ADHD first_anx first_crf first_dep first_dev first_NOS first_per first_phb first_psy first_ptsd first_sex first_slp first_str first_sub;
	array prev  [15] prev_MH  prev_ADHD  prev_anx  prev_crf  prev_dep  prev_dev  prev_NOS  prev_per  prev_phb  prev_psy  prev_ptsd  prev_sex  prev_slp  prev_str  prev_sub;

	do i = 1 to 15;
		if first[i] = . then first[i] = 169;
		if time_dx < first[i] then prev[i] = 0;
			else if time_dx >= first[i] then prev[i] = 1;
	end;

	drop PH DOD first_MH first_ADHD first_anx first_crf first_dep first_dev first_NOS first_per first_phb first_psy first_ptsd first_sex first_slp first_str first_sub;
run;

proc surveyfreq data = risk; weight MH_ipw;      table prev_MH  *injury / risk; ods output Risk2 = MH_rsk;   run; data Risk1; set MH_rsk;         run;
* Create clean MH comparison group before calculating risk;
data risk_in; set risk; if any_MH = 1 and any_str = 0 then delete; run;
proc surveyfreq data = risk_in; weight str_ipw;  table prev_str *injury / risk; ods output Risk2 = str_rsk;  run; data Risk1; set Risk1 str_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_ADHD = 0 then delete; run;
proc surveyfreq data = risk_in; weight ADHD_ipw; table prev_ADHD*injury / risk; ods output Risk2 = ADHD_rsk; run; data Risk1; set Risk1 ADHD_rsk; run;
data risk_in; set risk; if any_MH = 1 and any_anx = 0 then delete; run;
proc surveyfreq data = risk_in; weight anx_ipw;  table prev_anx *injury / risk; ods output Risk2 = anx_rsk;  run; data Risk1; set Risk1 anx_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_crf = 0 then delete; run;
proc surveyfreq data = risk_in; weight crf_ipw;  table prev_crf *injury / risk; ods output Risk2 = crf_rsk;  run; data Risk1; set Risk1 crf_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_dep = 0 then delete; run;
proc surveyfreq data = risk_in; weight dep_ipw;  table prev_dep *injury / risk; ods output Risk2 = dep_rsk;  run; data Risk1; set Risk1 dep_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_dev = 0 then delete; run;
proc surveyfreq data = risk_in; weight dev_ipw;  table prev_dev *injury / risk; ods output Risk2 = dev_rsk;  run; data Risk1; set Risk1 dev_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_per = 0 then delete; run;
proc surveyfreq data = risk_in; weight per_ipw;  table prev_per *injury / risk; ods output Risk2 = per_rsk;  run; data Risk1; set Risk1 per_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_phb = 0 then delete; run;
proc surveyfreq data = risk_in; weight phb_ipw;  table prev_phb *injury / risk; ods output Risk2 = phb_rsk;  run; data Risk1; set Risk1 phb_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_psy = 0 then delete; run;
proc surveyfreq data = risk_in; weight psy_ipw;  table prev_psy *injury / risk; ods output Risk2 = psy_rsk;  run; data Risk1; set Risk1 psy_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_ptsd = 0 then delete; run;
proc surveyfreq data = risk_in; weight ptsd_ipw; table prev_ptsd*injury / risk; ods output Risk2 = ptsd_rsk; run; data Risk1; set Risk1 ptsd_rsk; run;
data risk_in; set risk; if any_MH = 1 and any_sex = 0 then delete; run;
proc surveyfreq data = risk_in; weight sex_ipw;  table prev_sex *injury / risk; ods output Risk2 = sex_rsk;  run; data Risk1; set Risk1 sex_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_slp = 0 then delete; run;
proc surveyfreq data = risk_in; weight slp_ipw;  table prev_slp *injury / risk; ods output Risk2 = slp_rsk;  run; data Risk1; set Risk1 slp_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_sub = 0 then delete; run;
proc surveyfreq data = risk_in; weight sub_ipw;  table prev_sub *injury / risk; ods output Risk2 = sub_rsk;  run; data Risk1; set Risk1 sub_rsk;  run;
data risk_in; set risk; if any_MH = 1 and any_NOS = 0 then delete; run;
proc surveyfreq data = risk_in; weight NOS_ipw;  table prev_NOS *injury / risk; ods output Risk2 = NOS_rsk;  run; data Risk1; set Risk1 NOS_rsk;  run;

data Risk1; 
	set Risk1; 

	if Row ne "Total";

	if Row = "Row 1" then Row = "No MH";
	if Row = "Row 2" then Row = "MH";

	drop _SkipLine;
run;

proc export data = risk1
	outfile = "M:\p1074-renateh\2023_MHInjuries\MHInj_Figure3_Risks_05Apr2024.csv"
	dbms = csv
	replace;
run;

* Person-level N's for Clean MH/Inj vs Dirty analyses;
proc freq data = grp;
	table any_MH*any_str*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_anx*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_ADHD*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_crf*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_dep*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_dev*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_per*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_phb*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_psy*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_PTSD*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_sex*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_slp*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_sub*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
	table any_MH*any_NOS*any_inj*(Any_A Any_D Any_F Any_H Any_L Any_N Any_S) / list missing;
run;
