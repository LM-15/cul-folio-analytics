/* This query provides the total amount of voucher lines not sent to accounting (manuals) per account number*/

/* Change the lines below to filter or leave blank to return all results. Add details in '' for a specific filter.*/
WITH parameters AS (
	SELECT
        '2021-07-01'::DATE AS voucher_date_start_date, --ex:2000-01-01 
        '2022-06-30'::DATE AS voucher_date_end_date -- ex:2020-06-30 
),
ledger_fund AS (
	SELECT 
		fl.name,
		ff.external_account_no
	FROM finance_ledgers fl 
	LEFT JOIN 
		finance_funds AS ff ON FF.ledger_id = fl.id
	GROUP BY 
		external_account_no,
		fl.name
)
SELECT
	(SELECT
			voucher_date_start_date::varchar
     FROM
        	parameters) || ' to '::varchar || (
     SELECT
        	voucher_date_end_date::varchar
     FROM
        	parameters) AS date_range,	
	lf.name AS ledger_name,
	inv.vendor_invoice_no,
	org.erp_code AS vendor_erp_code,
	org.name AS vendor_name,
 	invvl.amount AS total_amt_spent_per_voucher_line,
 	 inv.note AS invoice_note
FROM
    invoice_vouchers AS invv
	LEFT JOIN INVOICE_VOUCHER_LINES AS invvl ON invvl.voucher_id = invv.id 
	LEFT JOIN invoice_invoices AS inv ON inv.id = invv.invoice_id
	LEFT JOIN ledger_fund AS lf ON lf.external_account_no = invvl.external_account_number
	LEFT JOIN organization_organizations AS org ON org.id = invv.vendor_id
WHERE 
	(invv.voucher_date >= (SELECT voucher_date_start_date FROM parameters)) 
	AND
	(invv.voucher_date < (SELECT voucher_date_end_date FROM parameters))
	AND inv.status LIKE 'Paid'
	AND invv.export_to_accounting = FALSE
GROUP BY 
	vendor_invoice_no,	
	lf.name,
	org.erp_code,
	org.name,
	invv.export_to_accounting,
	inv.note,
	invvl.amount
 ORDER BY
 	lf.name;
  
  
