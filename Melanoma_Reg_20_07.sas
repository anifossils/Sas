Libname anal "E:\Projects\BMS\13948 - Melanoma\Database\Analysis Data";

Data Mel_drug_data_p;
set anal.drug_data_final;
rename type = drug_type;
run;

Proc sql;
insert into Mel_drug_data_p
values( "Ipilimumab",8465978956,'19SEP2013'd,1,"DRU","N");
quit;

Data regimen_2(keep= ENROLID SVCDATE  drug_type1 end generic drug_type rename=(generic=drug_name 
drug_type1=drug_type SVCDATE=start enrolid=patient_id) drop =drug_type);
set Mel_drug_data_p;
format  end date9. drug_type1 $10. drug_type $10.;
end=SVCDATE+DAYSUPP-1;
if  drug_type ="C" then drug_type1= "Core";
else if  drug_type ="N" then drug_type1="Non_core";
else drug_type1=drug_type;
run;


Proc sort data=regimen_2;
by patient_id start;
run;


data regimen_3
 (keep=patient_id drug start_date end_date lot)
 ;
  set regimen_2;
  by patient_id notsorted;
  format start_date end_date date9.;

  /* look ahead at next record */
  set regimen_2( firstobs = 2 keep = start drug_type drug_name 
              rename = (start = next_start drug_type=next_type drug_name=next_drug) )
      regimen_2 (      obs = 1 drop = _all_ );
  next_start = ifn(last.patient_id, (.), next_start );
  next_type = ifc(last.patient_id, (.), next_type );
  next_drug = ifc(last.patient_id, (.), next_drug );
 
  /* set length of drug to be wide enough to fix all drugs */
  length drug $1000.;
  length hold_drug $1000.;
  array adrugs(100) $ 30 adrug1-adrug100;
  array adates(100) adate1-adate100;

  array hold_drugs(100) $ 30  hold_drug1-hold_drug100;
  array hold_dates(100) hold_date1-hold_date100;

 format adate1-adate20 date9.;
  retain start_date end_date drug days adrug: adate: hold_drug: hold_date:;
    
  /* initialize variables for first record within a given lot */
  if first.patient_id or counter eq 0 then do;
    if first.patient_id then do;
      lot=0;
      call missing (of adrugs(*));
      call missing (of adates(*));
      call missing (of hold_drugs(*));
      call missing (of hold_dates(*));
      dcounter=0;
    end;
    start_date=start;
    end_date=end;
    counter=1;
    drug='';
    hold_drug='';
          
    if drug_type eq 'Core' then do;
      drug=drug_name;
      dcounter+1;
      adrugs(dcounter)=drug_name;
      adates(dcounter)=end;
      do i=1 to dim(adrugs);
        if (not missing(adrugs(i))) and adates(i) ge start_date then do;
          if adrugs(i) ne strip(drug_name) then do;
            drug=catx('+',drug,adrugs(i));
            end_date=max(end_date,adates(i));
          end;
        end;
        else do;
          call missing(adrugs(i));
          call missing(adates(i));
        end;
      end;
    end;
    else do;
      call missing (of hold_drugs(*));
      call missing (of hold_dates(*));
      hold_drug=drug_name;
      dcounter+1;
      hold_drugs(dcounter)=drug_name;
      hold_dates(dcounter)=end;
    end;
    if next_start gt start_date+21-1 or missing(next_start) then do;
      days=60;
      if missing(drug) then do;
        drug=hold_drug;
        do i=1 to dim(adrugs);
          if (not missing(adrugs(i))) and adates(i) ge start_date then do;
            if strip(drug_name) ne adrugs(i) then drug=catx('+',drug,adrugs(i));
            end_date=max(end_date,adates(i));
          end;
          else do;
            call missing(adrugs(i));
            call missing(adates(i));
          end;
          if (not missing(hold_drugs(i))) and hold_dates(i) ge start_date then do;
            if strip(drug_name) ne hold_drugs(i) thend rug=catx('+',drug,hold_drugs(i));
            end_date=max(end_date,hold_dates(i));
          end;
          else do;
            call missing(hold_drugs(i));
            call missing(hold_dates(i));
          end;
        end;
        call missing(of hold_drugs(*));
        call missing(of hold_dates(*));
        call missing(hold_drug);
      end;
    end;
    else days=21;
  end;
  
  
  
  /* if not first record in lot and still within 21 day period check to see if drug in drug list */
  else if days eq 21 then do;
    if drug_type eq 'Core' then do;
      if not findw(drug,strip(drug_name)) then do;
        drug=catx('+',drug,drug_name);
        dcounter+1;
        adrugs(dcounter)=drug_name;
        adates(dcounter)=end;
      end;
      do i=1 to dim(adrugs);
        if drug_name eq adrugs(i) and adates(i) lt start_date then do;
          adates(i)=end;
        end;
      end;
      counter+1;
      end_date=max(end_date,end);
    end;
    
    else if missing(drug) then do;
      if not findw(hold_drug,strip(drug_name)) then do;
        hold_drug=catx('+',hold_drug,drug_name);
        dcounter+1;
        hold_drugs(dcounter)=drug_name;
        hold_dates(dcounter)=end;
      end;
      do i=1 to dim(adrugs);
        if drug_name eq hold_drugs(i) and hold_dates(i) lt /*start_date*/ end then do;
          hold_dates(i)=end;
        end;
      end;
      end_date=max(end_date,end);
      counter+1;
    end;
 
    /* add Non_core if lot already has at least one core */
    else do;
      if not findw(drug,strip(drug_name)) then do;
        drug=catx('+',drug,drug_name);
        dcounter+1;
        adrugs(dcounter)=drug_name;
        adates(dcounter)=end;
      end;
      counter+1;
    end;

    if next_start gt start_date+21 or missing(next_start) then do;
      days=60;
      if missing(drug) then do;
        drug=hold_drug;
        do i=1 to dim(adrugs);
          if (not missing(adrugs(i))) and adates(i) ge start_date then do;
/*             drug=catx('+',drug,adrugs(i)); */
            end_date=max(end_date,adates(i));
          end;
          else do;
            call missing(adrugs(i));
            call missing(adates(i));
          end;
          if (not missing(hold_drugs(i))) and hold_dates(i) ge start_date then do;
/*             drug=catx('+',drug,hold_drugs(i)); */
            end_date=max(end_date,hold_dates(i));
          end;
          else do;
            call missing(hold_drugs(i));
            call missing(hold_dates(i));
          end;
        end;
        call missing(of hold_drugs(*));
        call missing(of hold_dates(*));
        call missing(hold_drug);
      end;
    end;
  end;

  /* within 60 day check */
  else do;
    days=60;
    if start le end_date+60 and findw(drug,strip(drug_name)) /*and drug_type eq 'Core'*/ then do;
      counter+1;
      end_date=max(end,end_date);
      do i=1 to dim(adrugs);
        if adrugs(i) eq strip(drug_name) then do;
          adates(i)=max(adates(i),end);
        end;
      end;
    end;
  end;
*output;
  
  /* check to see if last.patient_id or next record indicates new lot */
  if last.patient_id or
     (counter gt 0 and
     days eq 60 and
     (next_start gt end_date+60 or
      ((not findw(drug,strip(next_drug))) and
       next_type eq 'Core')))
  then do;
    if not missing(next_start) and next_start le end_date then end_date=next_start-1;
    lot+1;
    output;

    counter=0;
  end;
run;




data xx;
set regimen_3;
where patient_id = 2795571701;
run;



