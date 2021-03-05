class GithubIntegrationModels < ActiveRecord::Migration[6.0]
  # rubocop:disable Metrics/AbcSize
  def change
    # see https://docs.github.com/en/rest/reference/pulls
    create_table :github_pull_requests do |t|
      t.references :github_user
      t.references :merged_by

      t.bigint :github_id # may be null if we receive a comment and just know the html_url
      t.integer :number, null: false
      t.string :github_html_url, null: false
      t.string :state, null: false
      t.string :repository, null: false
      t.datetime :github_updated_at
      t.string :title
      t.text :body
      t.boolean :draft
      t.boolean :merged
      t.datetime :merged_at
      t.integer :comments_count
      t.integer :review_comments_count
      t.integer :additions_count
      t.integer :deletions_count
      t.integer :changed_files_count
      t.json :labels # [{name, color}]
      t.timestamps
    end

    add_index :github_pull_requests, :github_html_url, unique: true
    add_index :github_pull_requests, :github_id, unique: true

    create_table :github_pull_requests_work_packages, if: false do |t|
      t.references :github_pull_request, null: false, index: {
        # the default index name was too long
        name: "index_github_pull_requests_work_packages_on_github_pr_id"
      }
      t.references :work_package, null: false
    end

    add_index(
      :github_pull_requests_work_packages,
      %i[github_pull_request_id work_package_id],
      unique: true,
      name: "unique_index_gh_prs_wps_on_gh_pr_id_and_wp_id"
    )

    # see: https://docs.github.com/en/rest/reference/users
    create_table :github_users do |t|
      t.references :user, null: true

      t.bigint :github_id, null: false
      t.string :github_login, null: false
      t.string :github_html_url, null: false
      t.string :github_avatar_url, null: false

      t.timestamps
    end

    add_index :github_users, :github_id, unique: true

    # see: https://docs.github.com/en/rest/reference/checks
    create_table :github_check_runs do |t|
      t.references :github_pull_request, null: false

      t.bigint :github_id, null: false
      t.string :github_html_url, null: false
      t.string :github_app_owner_avatar_url, null: false
      t.string :status, null: false
      t.string :conclusion
      t.string :output_title
      t.string :output_summary
      t.string :details_url
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :github_check_runs, :github_id, unique: true
  end
  # rubocop:enable Metrics/AbcSize
end
