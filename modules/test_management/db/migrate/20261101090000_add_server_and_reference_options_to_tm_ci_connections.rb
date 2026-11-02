# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/utils")

# Self-hosted follow-ups (0016):
# - server_url: canonical server of the connection ("https://gitlab.com",
#   "https://git.example.com/gitlab"), derived from base_url / the provider's default. Part of the
#   unique key, so a project can connect the same provider and repository path on gitlab.com and on
#   a self-hosted server (mirrors, migrations).
# - reference_name: qualifier of repo-qualified automation references ("shop:tests/x.spec.ts#…");
#   blank = the last segment of the repository path.
# - e2e_tests: auto | always | never – whether references written for this connection get the
#   "<name>/e2e:" qualifier (auto = detected from the report, see Automation::Reference).
# - scm_repository_id: the project's repository of the Repositories module attached to this
#   connection (source links via OpenProject's repository browser). Core table untouched.
class AddServerAndReferenceOptionsToTmCiConnections < ActiveRecord::Migration[8.0]
  include Migration::Utils

  DEFAULT_SERVERS = {
    "github" => "https://github.com",
    "gitlab" => "https://gitlab.com",
    "codeberg" => "https://codeberg.org"
  }.freeze

  def up
    change_table :tm_ci_connections, bulk: true do |t|
      t.string :server_url, limit: 512
      t.string :reference_name, limit: 100
      t.string :e2e_tests, limit: 10, null: false, default: "auto"
      t.references :scm_repository, foreign_key: { to_table: :repositories, on_delete: :nullify }, index: true
    end

    select_rows("SELECT id, provider, base_url FROM tm_ci_connections").each do |id, provider, base_url|
      url = self.class.canonical_server(base_url.presence || DEFAULT_SERVERS[provider])
      execute("UPDATE tm_ci_connections SET server_url = #{connection.quote(url.to_s)} WHERE id = #{id.to_i}")
    end
    change_column_null :tm_ci_connections, :server_url, false

    remove_index_on :tm_ci_connections, "index_tm_ci_connections_on_project_and_repo",
                    %w[project_id provider repository]
    add_index :tm_ci_connections, %i[project_id provider server_url repository], unique: true,
                                                                                 name: "index_tm_ci_connections_on_project_server_and_repo"
  end

  def down
    remove_index_on :tm_ci_connections, "index_tm_ci_connections_on_project_server_and_repo",
                    %w[project_id provider server_url repository]
    # Fails when the same provider + repository exists on two servers of one project; delete one first.
    add_index :tm_ci_connections, %i[project_id provider repository], unique: true,
                                                                      name: "index_tm_ci_connections_on_project_and_repo"
    change_table :tm_ci_connections, bulk: true do |t|
      t.remove_references :scm_repository, foreign_key: { to_table: :repositories }, index: true
      t.remove :server_url, :reference_name, :e2e_tests
    end
  end

  # Same rule as TestManagement::CiConnection.canonical_server (kept here so the migration does not
  # depend on the model).
  def self.canonical_server(url)
    uri = URI.parse(url.to_s.strip)
    return url.to_s.strip.downcase.chomp("/") unless uri.is_a?(URI::HTTP) && uri.host.present?

    port = uri.port == uri.default_port ? "" : ":#{uri.port}"
    "#{uri.scheme.downcase}://#{uri.host.downcase}#{port}#{uri.path.to_s.chomp('/').downcase}"
  rescue URI::InvalidURIError
    url.to_s.strip.downcase.chomp("/")
  end
end
