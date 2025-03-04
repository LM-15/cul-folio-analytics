--This query provides a fund details summary for active funds

WITH parameters AS (
    SELECT
        ''::VARCHAR AS fiscal_year_code,--Ex:FY22    NOTE: This is case sensitive.
        ''::VARCHAR AS fund_code,--Ex: 300, p1165    NOTE: This is case sensitive.
 	''::VARCHAR AS fund_name,--Ex: 300 Sciences CC, p1198 Mann Lib    NOTE: This is case sensitive. 
 	''::VARCHAR AS group_name -- Ex: Sciences, Central, Law....  NOTE: This is case sensitive. 
)
SELECT 
	CURRENT_DATE,
	ffy.code AS fiscal_yr_code,
	fl.code AS ledger_code,
	fl.name AS ledger_name,
	fft.name AS fund_type_name,
	ff.code AS fund_code,
	ff.name AS fund_name,
	ff.description AS fund_description,
	fg.name AS fund_group_name,
	COALESCE (fb.allocated,0) AS allocated,
	COALESCE (fb.net_transfers,0) AS net_transfers,
	COALESCE (fb.expenditures,0) AS expenditures,
	COALESCE (fb.encumbered,0) AS encumbered,
	COALESCE (fb.awaiting_payment,0) AS awaiting_payment,
	COALESCE (fb.unavailable,0) AS unavailable,-- This is the total of expended, awaiting payment and encumbered
	COALESCE(fb.available,0) AS available,
	COALESCE (unavailable / NULLIF(allocated,0)*100)::numeric(12,2)  AS perc_spent
FROM 
	finance_funds AS ff
	LEFT JOIN finance_group_fund_fiscal_years AS fgffy ON fgffy.fund_id = ff.id 
	LEFT JOIN finance_groups AS fg ON fg.id = fgffy.group_id
	LEFT JOIN finance_fund_types AS fft ON fft.id = ff.fund_type_id
	LEFT JOIN finance_fiscal_years AS ffy ON ffy.id = fgffy.fiscal_year_id
	LEFT JOIN finance_budgets AS fb ON fb.id = fgffy.budget_id AND ffy.id = fb.fiscal_year_id
	LEFT JOIN finance_ledgers AS fl ON fl.id = ff.ledger_id 
WHERE 
	ff.fund_status LIKE 'Active'
	AND ((ffy.code = (SELECT fiscal_year_code FROM parameters)) OR ((SELECT fiscal_year_code FROM parameters) = ''))
	AND ((ff.code = (SELECT fund_code FROM parameters)) OR ((SELECT fund_code FROM parameters) = ''))
	AND ((ff.name = (SELECT fund_name FROM parameters)) OR ((SELECT fund_name FROM parameters) = ''))
	AND ((fg.name = (SELECT group_name FROM parameters)) OR ((SELECT group_name FROM parameters) = ''))
ORDER BY 
	ledger_name,
	fund_type_name;
