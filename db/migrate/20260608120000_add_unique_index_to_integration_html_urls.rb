# frozen_string_literal: true

# The webhook URL is the only globally unique identifier stored for a pull
# request, merge request or issue: GitLab records hold only the per-project
# iid, which repeats across repositories, and GitHub records created from
# comment payloads carry no github_id at all. Enforce the URL's uniqueness at
# the database level so a missed lookup site or a concurrent webhook can never
# split one entity across two rows. Surviving duplicates are folded into the most recent row first;
# none are expected, since every write path already keys on the URL.
class AddUniqueIndexToIntegrationHtmlUrls < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  ENTITIES = {
    "github_pull_requests" => {
      url_column: "github_html_url",
      work_packages_join: { table: "github_pull_requests_work_packages", foreign_key: "github_pull_request_id" },
      children: { "github_check_runs" => "github_pull_request_id", "deploy_status_checks" => "github_pull_request_id" }
    },
    "gitlab_issues" => {
      url_column: "gitlab_html_url",
      work_packages_join: { table: "gitlab_issues_work_packages", foreign_key: "gitlab_issue_id" },
      children: {}
    },
    "gitlab_merge_requests" => {
      url_column: "gitlab_html_url",
      work_packages_join: { table: "gitlab_merge_requests_work_packages", foreign_key: "gitlab_merge_request_id" },
      children: { "gitlab_pipelines" => "gitlab_merge_request_id" }
    }
  }.freeze

  def up
    ENTITIES.each do |table, config|
      say_with_time "Deduplicating #{table} by #{config[:url_column]}" do
        transaction { fold_duplicates(table, config) }
      end
      add_index table, config[:url_column], unique: true, algorithm: :concurrently, if_not_exists: true
    end
  end

  def down
    ENTITIES.each do |table, config|
      remove_index table, config[:url_column], algorithm: :concurrently, if_exists: true
    end
  end

  private

  def fold_duplicates(table, config)
    move_work_packages_to_survivor(table, config)
    repoint_children(table, config)
    delete_duplicates(table, config[:url_column])
  end

  # Move the work packages of doomed rows onto the survivor, skipping links it already has.
  def move_work_packages_to_survivor(table, config)
    join_table = config[:work_packages_join][:table]
    foreign_key = config[:work_packages_join][:foreign_key]
    duplicates = duplicates_sql(table, config[:url_column])

    execute <<~SQL.squish
      INSERT INTO #{join_table} (#{foreign_key}, work_package_id)
      SELECT DISTINCT duplicates.keep_id, links.work_package_id
      FROM #{join_table} links
      JOIN (#{duplicates}) duplicates
        ON duplicates.dup_id = links.#{foreign_key}
      WHERE NOT EXISTS (
        SELECT 1 FROM #{join_table} existing
        WHERE existing.#{foreign_key} = duplicates.keep_id
          AND existing.work_package_id = links.work_package_id
      )
    SQL
    execute <<~SQL.squish
      DELETE FROM #{join_table} links
      USING (#{duplicates}) duplicates
      WHERE duplicates.dup_id = links.#{foreign_key}
    SQL
  end

  def repoint_children(table, config)
    config[:children].each do |child_table, foreign_key|
      execute <<~SQL.squish
        UPDATE #{child_table} child
        SET #{foreign_key} = duplicates.keep_id
        FROM (#{duplicates_sql(table, config[:url_column])}) duplicates
        WHERE duplicates.dup_id = child.#{foreign_key}
      SQL
    end
  end

  def delete_duplicates(table, url_column)
    execute <<~SQL.squish
      DELETE FROM #{table} target
      USING (#{duplicates_sql(table, url_column)}) duplicates
      WHERE duplicates.dup_id = target.id
    SQL
  end

  # Maps every duplicate row to the surviving (highest id) row sharing its URL.
  def duplicates_sql(table, url_column)
    <<~SQL.squish
      SELECT row.id AS dup_id, survivors.keep_id
      FROM #{table} row
      JOIN (
        SELECT #{url_column} AS url, MAX(id) AS keep_id
        FROM #{table}
        GROUP BY #{url_column}
        HAVING COUNT(*) > 1
      ) survivors ON survivors.url = row.#{url_column}
      WHERE row.id <> survivors.keep_id
    SQL
  end
end
