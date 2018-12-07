/*put data into the folder ./data; read data into sas*/
/*import dataset with infile command
data medicare;
 infile './data/Medicare_Provider_Util_Payment_PUF_CY2016.txt' dlm='09'x dsd;  (dsd: dlm=',', '09'x represent tab)
 input npi $ 10 ....
run;
*/


/*a*/
/*use proc import command*/
proc import datafile='./data/Medicare_Provider_Util_Payment_PUF_CY2016.txt' 
            out=mpup
            dbms=dlm
            replace; 
     delimiter='09'x;
run;


/*b*/
/*reduce to rows with MRI in the hcpcs_description and hcpc_code starts with 7*/
data reduced_dt;
  set mpup;
  if hcpcs_description=: 'MRI';    /*similar to like 'MRI%'in sql*/ 
  if hcpcs_code ge 70000 and hcpcs_code lt 80000;

proc print data=reduced_dt(obs=5);
  var hcpcs_description hcpcs_code;


/*c
  MRI procedures with the highest volume, highest total payment, 
and highest average payment among the procedures represented here.*/

/*calcuate pay for each patient*/
data result;
  set reduced_dt;
  pay=average_Medicare_payment_amt*line_srvc_cnt;

/*by procedures*/
/*sort by procedures*/
proc sort data=result;
 by  hcpcs_code ;

proc summary;
  by hcpcs_code hcpcs_description;
  output out=sum_result(replace=yes)
      sum(line_srvc_cnt)=volume
      sum(pay)=total;


data result(replace=yes);
  set sum_result;
  average=total/volume;
  keep hcpcs_code hcpcs_description volume total average;
  label hcpcs_code='code' 
        hcpcs_description='description';


/*highest value in each column*/
proc means data=result max;
  var volume total average;


data result(replace=yes);
  set result;
  if volume ge 1430104 or total ge 134223519 or average ge 269;


/*print table*/
proc print data=result noobs label;
  format volume 4.1 
         total 4.1
		 average 4.1;

/*save output*/
proc export data=result
   outfile='./data/ps4_q3c.csv'
   dbms=csv
   replace;


run;


proc sql;
  create table result_d1 as
    SELECT hcpcs_description as description, hcpcs_code as code,
    line_srvc_cnt as volume,average_Medicare_payment_amt*volume as pay
	FROM mpup
	WHERE description like 'MRI%' 
    AND code ge 70000
	AND code lt 80000;

create table result_d2 as
    SELECT distinct(code), description, sum(volume) AS vol, 
    sum(pay) AS total
	FROM result_d1
	group by code;

create table result_d3 as 
    SELECT code, description, vol, total, vol/total as average
	FROM result_d2;

create table result_d as 
    select max(vol), max(total), max(average)
	from result_d3
	group by code;
 
quit;


proc print data=result_d2(obs=5);
run;

proc sql;
  create table result_r as
    SELECT code, description, sum(volume) AS vol, 
    sum(pay) AS total, pay/volume AS average
	FROM result_d
	group by code;
 
quit;
