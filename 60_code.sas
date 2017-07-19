Data mel_drug_proc_ndc;
set anal.mel_drug_proc_ndc;
format end_date date9.;
end_date=svcdate + daysupp -1;
run;

Data diag_proc;
set anal.diag_proc;
run;


Data mel_drug_proc_ndc;
set mel_drug_proc_ndc;
if generic in ("NON-PVC INTRAVENOUS ADMINIST","Betaxolol Hydrochloride") then delete;
run;


Proc sql;
select distinct generic from  mel_drug_proc_ndc;
quit;


Proc sql;
create table day_60_rep as 
select a.enrolid,a.generic,a.svcdate,a.daysupp,b.date,a.end_date ,b.daysupp as daysup, date-end_date as gap_days
from mel_drug_proc_ndc as a 
left join 
diag_proc as b
on a.enrolid=b.enrolid
order by enrolid ,svcdate;
quit;


Proc sort data = day_60_rep out =day_60_rep_1;
by enrolid date;
run;

Data day_60_rep_2;
set day_60_rep_1;
if  gap_days < = 60;
run;


Proc sort data=day_60_rep_2 out=day_60_rep_3;
by enrolid date  gap_days;
run;

Data day_60_rep_4(keep=enrolid date daysup generic rename=(date=svcdate daysup=daysupp));
set day_60_rep_3;
by enrolid date gap_days;
if first.date;
run;

Data day_60_rep_5;
set day_60_rep_4;
format end_date date9.;
end_date = svcdate + daysupp -1 ;
run;

Data all_drug;
set mel_drug_proc_ndc day_60_rep_5 ;
by enrolid;
run;

Proc sort data=all_drug nodupkey;
by enrolid generic svcdate;
run;


data xx;
set regimen_4;
where patient_id = 1615100002;
run;

