Libname data "E:\Projects\BMS\13948 - Melanoma\Database\Source SAS Data";

Libname xx "C:\Users\aghosh\Desktop\XX";

Libname anal "E:\Projects\BMS\13948 - Melanoma\Database\Analysis Data";

Proc contents data=data.mel_drg ;
run;

Data nn;
set data.mel_drg ;
format admdate disdate date9.;
where proc1=" " and ndcnum=" ";
keep enrolid svcdate tsvcdat admdate disdate dx1-dx4 proc1 ndcnum drug_name daysupp  ;
run;

data mel_drg;
set data.mel_drg;
format svcdate tsvcdat admdate disdate date9.;
run;

proc sql;
create table abx as select *
from mel_drg
where enrolid in (2600297101,755834201,26945787302,941275601,1403614101)
order by enrolid;
quit;

Proc sql;
create table ndc_drug as select  distinct
ndcnum,drug_name 
from 
data.Mel_drg 
where ndcnum ne " " ;
quit;

Proc sql;
create table anal.ndc_drug2
as select a.*,
b.ROUTENAME,b.ndc,b.PROPRIETARYNAME,b.NONPROPRIETARYNAME,
case when drug_name in( "TRAMETINIB DIMETHYL SULFOXIDE" ,"TRAMETINIB DIMETHYL SULFOXIDE" ) then "ORAL"
     else routename 
	 end as routename1
from ndc_drug as a
left join xx.Ndc_final2 as b
on a.ndcnum=b.ndc
order by drug_name;
quit;


Proc sql;
create table impute_supp
as select a.*,b.routename1 as routename
from data.mel_drg as a
left join 
ndc_drug2 as b
on a.ndcnum=b.ndcnum and a.ndcnum ne " " and a.daysupp = 0;
quit;

data mel_drg;
set impute_supp;
days_proc=tsvcdat - svcdate+1;
where ndcnum ne " ";
keep enrolid svcdate tsvcdat proc1 ndcnum drug_name daysupp days_proc routename;
run;

Proc sql;
create table drug_data as select 
enrolid,a.drug_name,svcdate as drug_date,tsvcdat format=date9.,routename,
case when ( daysupp = . and proc1 ne " ") then days_proc
     when ( daysupp = . and proc1 eq " " and ndcnum eq " ") then 1
else daysupp
end as days_supply
from mel_drg as a
order by enrolid
;
quit;

Data anal.drug_data;
set drug_data;
if days_supply = 0 then do;
if routename = "ORAL" then days_sup = 28;
else days_sup=1;
end;
else do;
days_sup= days_supply;
end;
run;


Data xx;
set anal.Mel_drug_data_p;
where daysupp = 0;
run;

Data xxx;
set data.mel_drg;
where daysupp = 0;
run;





Proc freq data=data.non_mel_drg;
tables ndcnum;
run;




