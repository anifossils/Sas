libname anal "\\192.168.1.102\apld\13480_RSV\Data\ADS\Otitis";


data index_data;
	set anal.index_data_inc_asth_resp_otitis;
if Pneu_Inf_fg = "Y" or preterm_fg = "Y" or resp_asth_add_fg = "Y" or Neuro_fg = "Y" or Other_fg = "Y" or DownSyn_fg = "Y" or
	Cystic_fg = "Y" or CVD_fg = "Y" or BPD_fg = "Y" then any_risk_new = "Y";
else any_risk_new = "N";
keep ptid index_date gender age Pneu_Inf_fg Preterm_fg resp_asth_add_fg Neuro_fg Other_fg  DownSyn_fg Cystic_fg CVD_fg BPD_fg any_risk_new;

run;

proc sql;
create table otitis_pat_index_3yr as 
select 
a.*,
b.Preterm_fg ,
b.CVD_fg,
b.DownSyn_fg,
b.Other_fg ,
b.Neuro_fg,
b.Cystic_fg,
b.Pneu_Inf_fg ,
b.BPD_fg,
b.resp_asth_add_fg ,
b.any_risk_new
from 
anal.otitis_pat_index_3yr a
left join 
index_data b
on a.ptid = b.ptid;
quit;


data logistic_3yr;
	set otitis_pat_index_3yr; 
	if race = 'Caucasian' then Caucasian = 'Y';
	else Caucasian = 'N';
run;

/****************************************/
/*********Oversll****************/
/****************************************/
%macro risk(any_risk_fg);
proc freq data=logistic_3yr;
table age_0_2 gender Caucasian  prior_synagys  &any_risk_fg. rsv_hosp_new RSV_diag_season;
where age_0_2 = 'Y';
run;

proc logistic data=logistic_3yr;
	class gender(ref='Female') Caucasian(ref='N') prior_synagys(ref='N') rsv_hosp_new (ref='N') &any_risk_fg.(ref='N') RSV_diag_season(ref='N');
	model otitis(ref='N') = gender Caucasian prior_synagys &any_risk_fg. rsv_hosp_new  RSV_diag_season;
	where age_0_2 = 'Y';
run;

proc freq data=logistic_3yr;
table age_0_2 gender Caucasian  prior_synagys  &any_risk_fg. rsv_hosp_new RSV_diag_season;
where age_0_2_bih = 'Y';
run;

proc logistic data=logistic_3yr;
	class gender(ref='Female') Caucasian(ref='N')  prior_synagys(ref='N')  rsv_hosp_new (ref='N') &any_risk_fg.(ref='N') RSV_diag_season(ref='N');
	model otitis(ref='N') = gender Caucasian  prior_synagys &any_risk_fg. rsv_hosp_new   RSV_diag_season;
	where age_0_2_bih = 'Y';
run;


/****************************************/
/*********Hosp. Patients****************/
/****************************************/

proc freq data=logistic_3yr;
table age_0_2 gender Caucasian  prior_synagys &any_risk_fg. RSV_diag_season LOS_7d_Q4;
where rsv_hosp_new = 'Y' and age_0_2 = 'Y';
run;	

proc logistic data=logistic_3yr;
	class gender(ref='Female') Caucasian(ref='N') prior_synagys(ref='N') &any_risk_fg.(ref='N') RSV_diag_season(ref='N')
		  LOS_7d_Q4(ref='1. LE 7 days');
	model otitis(ref='N') = gender Caucasian prior_synagys &any_risk_fg. RSV_diag_season LOS_7d_Q4;
	where rsv_hosp_new = 'Y' and age_0_2 = 'Y';
run;

proc freq data=logistic_3yr;
table age_0_2 gender Caucasian  prior_synagys &any_risk_fg. RSV_diag_season LOS_7d_Q4;
where rsv_hosp_new = 'Y' and age_0_2_bih = 'Y';
run;

proc logistic data=logistic_3yr;
	class gender(ref='Female') Caucasian(ref='N') 
		  LOS_7d_Q4(ref='1. LE 7 days');
	model otitis(ref='N') = gender Caucasian     LOS_7d_Q4;
	where rsv_hosp_new = 'Y' and age_0_2_bih = 'Y';
run;
%mend risk;
%risk(CVD_fg);
%risk(Neuro_fg);*remove neuro flag from last logistic regression  ;
%risk(BPD_fg);*remove BPD flag from last logistic regression ;
%risk(Cystic_fg);*remove  cystic flag  fibrosis  from all last logistic regression ;

