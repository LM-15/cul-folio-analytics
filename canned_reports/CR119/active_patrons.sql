/*This report contains a list of active patrons, including netids, names, addresses, patron group, and patron blocks. 
To get a list of active AND inactive patrons, delete last line of the report, which is "and ug.active=TRUE"
*/

WITH parameters AS (
    SELECT
        /* Fill in an address type */
   		/*NOTE: As users have multiple addresses, and each address is on a separate row, leaving the address type filter will result in multiple records per user*/
        'Campus'::varchar AS address_type_name_filter, --Example: Home, Campus, Claim
        /* Fill in a custom field to include in the report */
        ''::varchar AS custom_field_filter,--Example: college
        /* Fill in patron filters */
        '2000-01-01'::date AS created_after_filter, -- use early date to include all users
        '2000-01-01'::date AS updated_after_filter, -- Example: 2021-06-02
        /*Leave patron group filter blank to get all patron groups*/
        'Undergraduate'::varchar AS patron_group_filter, -- Example: Undergraduate, Graduate, Faculty, Staff
        ''::varchar AS active_status_filter, -- can be true or false (or '' for either)
        ''::varchar AS is_blocked_filter -- can be true or false (or '' for either)
        ),
user_notes AS (
    SELECT
        json_extract_path_text(links.data, 'id') AS user_id,
        string_agg(DISTINCT nt."content", '|') AS notes_list
    FROM
        notes AS nt
        CROSS JOIN json_array_elements(json_extract_path(data, 'links')) AS links (data)
    WHERE json_extract_path_text(links.data, 'type') = 'user'
    GROUP BY
        json_extract_path_text(links.data, 'id')
),
user_custom_fields AS (
    SELECT
        id AS user_id,
        (SELECT custom_field_filter FROM parameters) AS custom_field_name,
        json_extract_path_text(data, 'customFields', (SELECT custom_field_filter FROM parameters)) AS 
          custom_field_value
    FROM
        user_users AS uu
    WHERE
        json_extract_path_text(data, 'customFields', (SELECT custom_field_filter FROM parameters)) IS NOT NULL
),
user_depts AS (
    SELECT
        user_id,
        string_agg(DISTINCT department_name, '|') AS depts_list
    FROM
        folio_reporting.users_departments_unpacked
    GROUP BY
        user_id
),
user_addresses AS (
    SELECT
        user_id,
        address_id,
        address_line_1,
        address_line_2,
        address_city,
        address_region,
        address_country_id,
        address_postal_code,
        address_type_id,
        address_type_name,
        address_type_description,
        is_primary_address
    FROM
        folio_reporting.users_addresses
    WHERE address_type_name = (SELECT address_type_name_filter FROM parameters)
        OR '' = (SELECT address_type_name_filter FROM parameters)        
)
SELECT
    ug.user_id,
    ug.barcode,
    ug.username,
    ug.external_system_id,
    ug.user_last_name, 
    ug.user_first_name, 
    ug.user_middle_name, 
    ug.user_preferred_first_name,
    ug.user_email,
    ug.group_name,
    ug.created_date,
    ug.expiration_date,
    ug.updated_date,
    ug.active,
    un.notes_list AS user_notes,
    ud.depts_list,
    json_extract_path_text(uu.data, 'customFields') AS user_all_custom_fields,
    ucf.custom_field_name,
    ucf.custom_field_value,
    /*mb.code IS NOT NULL AS blocked,
    mb.code AS block_code,
    mb.desc AS block_description,
    mb.patron_message AS block_patron_message,
    mb.type AS block_type,
    mb.expiration_date AS block_expiration_date,
    mb.borrowing AS block_borrowing_yn,
    mb.renewals AS block_renewals_yn,
    mb.requests AS block_requests_yn,
    json_extract_path_text(mb.data, 'metadata', 'createdDate') AS block_created_date,*/
  --json_extract_path_text(uu.data, 'personal', 'addresses') AS user_all_addresses,
    address_line_1,
    address_line_2,
    address_city,
    address_region,
    address_country_id,
    address_postal_code,
    address_type_name,
    address_type_description,
    is_primary_address
 FROM
    folio_reporting.users_groups AS ug
    LEFT JOIN user_notes AS un ON ug.user_id = un.user_id
    LEFT JOIN public.user_users AS uu ON ug.user_id = uu.id
    LEFT JOIN user_depts AS ud ON ug.user_id = ud.user_id
  --LEFT JOIN public.feesfines_manualblocks AS mb ON ug.user_id = mb.user_id
    LEFT JOIN user_addresses AS ua ON ug.user_id = ua.user_id
    LEFT JOIN user_custom_fields AS ucf ON ug.user_id = ucf.user_id
 WHERE 
    (group_name = (SELECT patron_group_filter FROM parameters)
        OR '' = (SELECT patron_group_filter FROM parameters))
    AND (ug.active::varchar = (SELECT active_status_filter FROM parameters)
        OR '' = (SELECT active_status_filter FROM parameters))
  --  AND (mb.code IS NOT NULL::varchar = (SELECT is_blocked_filter FROM parameters)
  --      OR '' = (SELECT is_blocked_filter FROM parameters))
    AND ug.created_date >= (SELECT created_after_filter FROM parameters)
    AND ug.updated_date >= (SELECT updated_after_filter FROM parameters)
    and ug.active=TRUE

;
