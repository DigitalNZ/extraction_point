defmodule ExtractionPoint.DataChange.Contributions do
  def update_with_creator(source_table, class_name, target_table) do
    ~s"""
    WITH c_query AS
    (SELECT
    T1.id,
    C_AGG.contributed_item_id,
    C_AGG.creator_id,
    C_AGG.creator_login,
    C_AGG.creator_name
    FROM #{source_table} T1
    JOIN
    (SELECT C.contributed_item_id, C.contributed_item_type,
    C.user_id AS creator_id,
    U.login AS creator_login,
    U.resolved_name AS creator_name
    FROM contributions C
    JOIN users U ON (U.id = C.user_id)
    WHERE C.contributor_role = 'creator') C_AGG
    ON (C_AGG.contributed_item_id = T1.id
    AND C_AGG.contributed_item_type = '#{class_name}'))

    UPDATE #{target_table}
    SET creator_id = c_query.creator_id,
    creator_login = c_query.creator_login,
    creator_name = c_query.creator_name
    FROM c_query
    WHERE #{target_table}.id = c_query.contributed_item_id;
    """
  end

  def update_with_contributors(source_table, class_name, target_table) do
    ~s"""
    WITH c_query AS
    (SELECT
    T1.id,
    C_AGG.contributed_item_id,
    C_AGG.contributor_ids,
    C_AGG.contributor_logins,
    C_AGG.contributor_names
    FROM #{source_table} T1
    JOIN
    (SELECT C.contributed_item_id, C.contributed_item_type,
    ARRAY_AGG(DISTINCT(U.id)) AS contributor_ids,
    ARRAY_AGG(DISTINCT(U.login)) AS contributor_logins,
    ARRAY_AGG(DISTINCT(U.resolved_name)) AS contributor_names
    FROM contributions C
    JOIN users U ON (U.id = C.user_id)
    WHERE C.contributor_role != 'creator'
    GROUP BY C.contributed_item_id, C.contributed_item_type) C_AGG
    ON (C_AGG.contributed_item_id = T1.id AND C_AGG.contributed_item_type = '#{class_name}'))

    UPDATE #{target_table}
    SET contributor_ids = ARRAY_REMOVE(c_query.contributor_ids, #{target_table}.creator_id),
    contributor_logins = ARRAY_REMOVE(c_query.contributor_logins::text[], #{target_table}.creator_login),
    contributor_names = ARRAY_REMOVE(c_query.contributor_names::text[], #{target_table}.creator_name)
    FROM c_query
    WHERE #{target_table}.id = c_query.contributed_item_id;
    """
  end
end
