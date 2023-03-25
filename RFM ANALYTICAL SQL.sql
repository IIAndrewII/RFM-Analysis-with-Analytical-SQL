-- 1- let's first get familiar with the data 

select * from tableretail;

select distinct(Invoice) , sum(QUANTITY)over(partition by Invoice) QUAN_per_Invoice
        from tableretail
        order by QUAN_per_Invoice;
        
select AVG(QUAN_per_Invoice) ,min( QUAN_per_Invoice) , max(QUAN_per_Invoice)
        From(
                    select distinct(Invoice) , sum(QUANTITY)over(partition by Invoice) QUAN_per_Invoice
                    from tableretail);


-- the avrage quantity per Invoice is approximately 250, near to the min. value(1) and very far from the max. value(11848)
-- So, The data is right-skewed



select AVG(Price_per_Invoice) ,min( Price_per_Invoice) , max(Price_per_Invoice)
        From(
                    select distinct(Invoice) , sum(QUANTITY*Price)over(partition by Invoice) Price_per_Invoice
                    from tableretail);
-- the avrage PRICE  per Invoice is approximately  360, near to the min. value(0) and very far from the max. value(18841.48)
-- So, The data is right-skewed (same as the avrage quantity)



select distinct(CUSTOMER_ID),               
            AVG(PRICE*QUANTITY) over(partition by CUSTOMER_ID) AVG_Total_PRICE,
            MIN(PRICE*QUANTITY) over(partition by CUSTOMER_ID) MIN_Total_PRICE,
            MAX(PRICE*QUANTITY) over(partition by CUSTOMER_ID) MAX_Total_PRICE    
from tableretail
order by AVG_Total_PRICE desc ;
-- Most of the revenue of the online store from customers with average price less than 100



select distinct(CUSTOMER_ID),               
            AVG(QUANTITY) over(partition by CUSTOMER_ID) AVG_QUANTITY,
            MIN(QUANTITY) over(partition by CUSTOMER_ID) MIN_QUANTITY,
            MAX(QUANTITY) over(partition by CUSTOMER_ID) MAX_QUANTITY    
from tableretail
order by AVG_QUANTITY desc ;
-- Most of the revenue of the online store from customers with average quantity less than 40



select  distinct(COUNTRY), count(*)over(partition by COUNTRY) count
from tableretail;
-- All the revenue of the online store from United Kingdom only



select  distinct(TO_CHAR(trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month'),'YYYY-MM'))     INVOICE_DATE,
            AVG(QUANTITY) over(partition by trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month')) AVG_QUANTITY,
            AVG(PRICE*QUANTITY) over(partition by trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month')) AVG_PRICE
from tableretail
order by INVOICE_DATE ;
-- I will use this output in the next 2 queries

select INVOICE_DATE, AVG_QUANTITY, rank()over(order by AVG_QUANTITY desc) QUANTITY_RANC
from(
                    select  distinct(TO_CHAR(trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month'),'YYYY-MM'))     INVOICE_DATE,
                                AVG(QUANTITY) over(partition by trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month')) AVG_QUANTITY
                    from tableretail
                    order by INVOICE_DATE );
-- December has the lowest quantities in both 2010,2011 while 2011-08 has the highest quantities
 

                   
select INVOICE_DATE, AVG_PRICE, rank()over(order by AVG_PRICE desc) PRICE_RANC
from(
                    select  distinct(TO_CHAR(trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month'),'YYYY-MM'))     INVOICE_DATE,
                                AVG(PRICE*QUANTITY) over(partition by trunc(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'), 'Month')) AVG_PRICE
                    from tableretail
                    order by INVOICE_DATE );
-- December has the lowest Price in both 2010,2011 while 2011-08 has the highest Price (same as quantities)
        


----------------------------------------------------------------------------------------------------------------------------------------------------     
--  2- RFM Analysis

-- Step 1 (get Recency, freguency, monetary, avg(freguency, monetary))
select distinct(CUSTOMER_ID),
            max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over() - max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over(partition by CUSTOMER_ID) Recency,
            count(*)over( partition by CUSTOMER_ID ) frequency,
            sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ) monetary,
            (count(*)over( partition by CUSTOMER_ID ) + sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ))/2 avg_FM
from tableretail;

-- Step 2  break the resultset into approximately equal groups 
select CUSTOMER_ID, Recency, frequency, monetary,
        NTILE(5) over(order by Recency)  R_Score,
        NTILE(5) over(order by avg_FM)  FM_Score
        from(      
                select distinct(CUSTOMER_ID),
                            max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over() - max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over(partition by CUSTOMER_ID) Recency,
                            count(*)over( partition by CUSTOMER_ID ) frequency,
                            sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ) monetary,
                            (count(*)over( partition by CUSTOMER_ID ) + sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ))/2 avg_FM
                from tableretail);

-- Step 3 (add labels)

 select CUSTOMER_ID, Recency, freguency, monetary, R_Score, FM_Score, 
           CASE WHEN R_Score = 5 AND FM_Score = 5 THEN 'Champions' 
            WHEN R_Score = 5 AND FM_Score = 4 THEN 'Champions' 
            WHEN R_Score = 4 AND FM_Score = 5 THEN 'Champions' 

            WHEN R_Score = 5 AND FM_Score = 2 THEN 'Potential Loyalists' 
            WHEN R_Score = 4 AND FM_Score = 2 THEN 'Potential Loyalists' 
            WHEN R_Score = 3 AND FM_Score = 3 THEN 'Potential Loyalists' 
            WHEN R_Score = 4 AND FM_Score = 3 THEN 'Potential Loyalists' 

            WHEN R_Score = 5 AND FM_Score = 3 THEN 'Loyal Customers' 
            WHEN R_Score = 4 AND FM_Score = 4 THEN 'Loyal Customers' 
            WHEN R_Score = 3 AND FM_Score = 5 THEN 'Loyal Customers' 
            WHEN R_Score = 3 AND FM_Score = 4 THEN 'Loyal Customers' 

            WHEN R_Score = 5 AND FM_Score = 1 THEN 'Recent Customers' 
           
            WHEN R_Score = 4 AND FM_Score = 1 THEN 'Promising' 
            WHEN R_Score = 3 AND FM_Score = 1 THEN 'Promising' 

            WHEN R_Score = 3 AND FM_Score = 2 THEN 'Customers Needing Attention' 
            WHEN R_Score = 2 AND FM_Score = 3 THEN 'Customers Needing Attention' 
            WHEN R_Score = 2 AND FM_Score = 2 THEN 'Customers Needing Attention' 

            WHEN R_Score = 2 AND FM_Score = 5 THEN 'At Risk' 
            WHEN R_Score = 2 AND FM_Score = 4 THEN 'At Risk' 
            WHEN R_Score = 1 AND FM_Score = 3 THEN 'At Risk' 

            WHEN R_Score = 1 AND FM_Score = 5 THEN 'Cannot Lose Them' 
            WHEN R_Score = 1 AND FM_Score = 4 THEN 'Cannot Lose Them' 

            WHEN R_Score = 1 AND FM_Score = 2 THEN 'Hibernating' 

            WHEN R_Score = 2 AND FM_Score = 1 THEN 'About to Sleep' 
            
            WHEN R_Score = 1 AND FM_Score = 1 THEN 'Lost' 
           End CUSTOMER_SEGMENT
            from(
            select CUSTOMER_ID, Recency, freguency, monetary,
                    NTILE(5) over(order by Recency)  R_Score,
                    NTILE(5) over(order by avg_FM)  FM_Score
                    from(      
                            select distinct(CUSTOMER_ID),
                                        max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over() - max(to_date( INVOICEDATE, 'MM/DD/YYYY HH24:MI'))over(partition by CUSTOMER_ID) Recency,
                                        count(*)over( partition by CUSTOMER_ID ) freguency,
                                        sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ) monetary,
                                        (count(*)over( partition by CUSTOMER_ID ) + sum(PRICE*QUANTITY)over( partition by CUSTOMER_ID ))/2 avg_FM
                            from tableretail));









        
