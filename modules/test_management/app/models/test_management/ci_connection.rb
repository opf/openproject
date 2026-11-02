# frozen_string_literal: true

module TestManagement
  # A CI system that reports automated test results into a project and (0011) can be
  # triggered from it ("Run in CI"). A project can have several connections, e.g. the web app
  # on GitHub and the mobile app on GitLab.
  #
  # Providers and what "repository" holds:
  #   github / gitea / forgejo / codeberg – owner/repo        (workflow = workflow file, e.g. tm.yml)
  #   gitlab                              – group/sub/project
  #   jenkins                             – job path, folders separated by "/" (e.g. qa/e2e)
  #   woodpecker                          – numeric Woodpecker repository id
  # codeberg is Forgejo on https://codeberg.org; gitea, forgejo, jenkins and woodpecker need a base URL.
  #
  # The connection decides how uploads are filed when the upload itself does not say so:
  #   ingest_mode new_run       – every CI pipeline creates a new run (default, 0008 behavior)
  #   ingest_mode new_iteration – every pipeline adds an iteration to the active run named
  #                               target_run_name ("Smoke", "Regression", …)
  #
  # Secrets (both optional, stored encrypted, write-only – no reader returns them):
  #   token          – API token: "Check connection" and the trigger (GitHub/Gitea/Forgejo/Codeberg/
  #                    Woodpecker token, Jenkins user API token, GitLab token for the check only)
  #   trigger_token  – GitLab pipeline trigger token, or the Jenkins "Trigger builds remotely" token
  #
  # Self-hosted servers (0015):
  #   base_url may contain a path (GitLab relative URL root https://host/gitlab, Gitea ROOT_URL
  #   https://host/git, Jenkins prefix https://host/jenkins); every API URL is built below it.
  #   ca_certificate – optional PEM bundle of an internal CA, trusted *in addition to* the system
  #                    store for this connection only (see CiConnections::Http). No option to
  #                    switch TLS verification off exists, on purpose.
  #   inbound_only   – OpenProject never calls the server (CI -> OpenProject only): no check, no
  #                    trigger, no pull-request source; "Run in CI" shows the values to start the
  #                    pipeline by hand (CiTriggers::ManualStart).
  #
  # Follow-ups (0016):
  #   server_url     – canonical server ("https://gitlab.com", "https://git.example.com/gitlab"),
  #                    derived from base_url on every save; part of the unique key (project,
  #                    provider, server_url, repository), so gitlab.com and a self-hosted GitLab may
  #                    both have "group/app" in one project.
  #   reference_name – qualifier of repo-qualified automation references ("shop:tests/a.spec.ts#…",
  #                    Automation::Reference); blank = last segment of the repository path.
  #   e2e_tests      – auto | always | never: whether references written for this connection are
  #                    qualified "<name>/e2e:" (auto = detected per test, see Automation::Reference).
  #   scm_repository – the project's repository of the Repositories module, attached as source for
  #                    links (OpenProject's repository browser). Nothing is sent to it.
  class CiConnection < ApplicationRecord
    self.table_name = "tm_ci_connections"
    self.filter_attributes += %i[token_ciphertext trigger_token_ciphertext]

    PROVIDERS = %w[github gitlab jenkins gitea forgejo codeberg woodpecker].freeze
    # Providers whose trigger is a workflow_dispatch of a workflow file.
    WORKFLOW_PROVIDERS = %w[github gitea forgejo codeberg].freeze
    INGEST_MODES = %w[new_run new_iteration].freeze
    DEFAULT_BASE_URLS = {
      "github" => "https://github.com",
      "gitlab" => "https://gitlab.com",
      "codeberg" => "https://codeberg.org"
    }.freeze
    CHECK_STATUSES = %w[ok unauthorized not_found error].freeze
    OWNER_REPO = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\z}
    REPOSITORY_FORMATS = {
      "github" => OWNER_REPO,
      "gitea" => OWNER_REPO,
      "forgejo" => OWNER_REPO,
      "codeberg" => OWNER_REPO,
      "gitlab" => %r{\A[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+\z},
      "jenkins" => %r{\A[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*\z},
      "woodpecker" => /\A[1-9][0-9]{0,18}\z/
    }.freeze
    WORKFLOW_FORMAT = /\A[A-Za-z0-9_.-]+\.ya?ml\z/
    REF_FORMAT = %r{\A[A-Za-z0-9_./-]+\z}
    CA_MAX_BYTES = 65_536
    CA_MAX_CERTIFICATES = 10
    PEM_CERTIFICATE = /-----BEGIN CERTIFICATE-----[A-Za-z0-9+\/=\s]+?-----END CERTIFICATE-----/
    # Servers with a forge (source browsing, pull / merge requests); Jenkins and Woodpecker are CI only.
    FORGE_PROVIDERS = %w[github gitlab gitea forgejo codeberg].freeze
    E2E_MODES = %w[auto always never].freeze
    REFERENCE_NAME_FORMAT = /\A[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\z/

    belongs_to :project
    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :scm_repository, class_name: "::Repository", optional: true
    has_many :test_runs, class_name: "TestManagement::TestRun", foreign_key: :connection_id,
                         inverse_of: :connection, dependent: :nullify
    has_many :iterations, class_name: "TestManagement::TestRunIteration", foreign_key: :connection_id,
                          inverse_of: :connection, dependent: :nullify

    before_validation :normalize

    validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :project_id, case_sensitive: false }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :repository, presence: true, length: { maximum: 255 },
                           uniqueness: { scope: %i[project_id provider server_url], case_sensitive: false }
    validates :e2e_tests, inclusion: { in: E2E_MODES }
    validates :reference_name, format: { with: REFERENCE_NAME_FORMAT }, allow_blank: true
    validates :ingest_mode, inclusion: { in: INGEST_MODES }
    validates :target_run_name, length: { maximum: 255 }
    validates :target_run_name, presence: true, if: -> { ingest_mode == "new_iteration" }
    validates :check_status, inclusion: { in: CHECK_STATUSES }, allow_nil: true
    validates :workflow, :trigger_ref, :ci_username, length: { maximum: 255 }
    validates :workflow, format: { with: WORKFLOW_FORMAT }, allow_blank: true
    validates :trigger_ref, format: { with: REF_FORMAT }, allow_blank: true
    validates :base_url, presence: true, if: -> { provider.present? && !DEFAULT_BASE_URLS.key?(provider) }
    validate :repository_format
    validate :base_url_format
    validate :token_reentered_for_new_endpoint
    validate :ca_certificate_format
    validate :scm_repository_of_project

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(Arel.sql("LOWER(tm_ci_connections.name)"), :id) }

    # --- token (write-only) -------------------------------------------------------
    # Assigning a blank value keeps the stored token (forms never echo it back);
    # use #clear_token! / remove_token = "1" to delete it.
    # Write-only: the reader never returns the secret. It exists so that validation
    # errors on :token can be rendered (ActiveModel reads the attribute value).
    def token = nil

    def token=(value)
      return if value.blank?

      self.token_ciphertext = CiTokenCipher.encrypt(value.to_s.strip)
      self.token_updated_at = Time.current
    end

    # Readers for the write-only flags. Contracts are Disposable twins that read every declared
    # attribute when they are built (0019b: without them every create/update raised NoMethodError).
    def remove_token = nil

    def remove_trigger_token = nil

    def remove_token=(value)
      return unless ActiveModel::Type::Boolean.new.cast(value)

      self.token_ciphertext = nil
      self.token_updated_at = Time.current
    end

    def token_set?
      token_ciphertext.present?
    end

    # Only for outbound calls to the CI provider. Never render this.
    def decrypted_token
      CiTokenCipher.decrypt(token_ciphertext)
    end

    def token_readable?
      token_set? && decrypted_token.present?
    end

    # --- trigger token (write-only, same rules as the token) ------------------------
    def trigger_token = nil

    def trigger_token=(value)
      return if value.blank?

      self.trigger_token_ciphertext = CiTokenCipher.encrypt(value.to_s.strip)
      self.trigger_token_updated_at = Time.current
    end

    def remove_trigger_token=(value)
      return unless ActiveModel::Type::Boolean.new.cast(value)

      self.trigger_token_ciphertext = nil
      self.trigger_token_updated_at = Time.current
    end

    def trigger_token_set?
      trigger_token_ciphertext.present?
    end

    # Only for outbound calls to the CI provider. Never render this.
    def decrypted_trigger_token
      CiTokenCipher.decrypt(trigger_token_ciphertext)
    end

    def serializable_hash(options = nil)
      options = (options || {}).dup
      options[:except] = Array(options[:except]) + %w[token_ciphertext trigger_token_ciphertext]
      super
    end

    # --- self-hosted servers (0015) -------------------------------------------------
    def outbound?
      !inbound_only?
    end

    def forge?
      FORGE_PROVIDERS.include?(provider)
    end

    # The CA certificates of ca_certificate (empty when none or unreadable).
    def ca_certificates
      return [] if ca_certificate.blank?

      ca_certificate.scan(PEM_CERTIFICATE).map { |pem| OpenSSL::X509::Certificate.new(pem) }
    rescue OpenSSL::X509::CertificateError
      []
    end

    # System trust store plus ca_certificates, or nil when the connection has no own CA
    # (then the default store applies, which honors SSL_CERT_FILE / SSL_CERT_DIR).
    def ca_cert_store
      certificates = ca_certificates
      return nil if certificates.empty?

      store = OpenSSL::X509::Store.new
      store.set_default_paths
      certificates.each do |certificate|
        store.add_cert(certificate)
      rescue OpenSSL::X509::StoreError
        next # already in the system store
      end
      store
    end

    # "CN=Corp Root CA (valid until 2030-01-01)" per certificate, for the settings page.
    def ca_summary
      ca_certificates.map do |certificate|
        name = certificate.subject.to_a.find { |entry| entry[0] == "CN" }&.dig(1) || certificate.subject.to_s
        { name:, not_after: certificate.not_after, expired: certificate.not_after < Time.current }
      end
    end

    # Web URL of a file in the repository (forges only), e.g. for an automation reference
    # "tests/login.spec.ts#…" -> https://git.example.com/gitlab/group/app/-/blob/<ref>/tests/login.spec.ts
    def file_url(path, ref: nil)
      return nil unless forge?

      path = path.to_s.strip.delete_prefix("./").delete_prefix("/")
      return nil if path.blank? || path.include?("..") || path.match?(%r{\A[a-z][a-z0-9+.-]*://}i)

      ref = (ref.presence || effective_trigger_ref).to_s
      encoded = path.split("/").map { |segment| ERB::Util.url_encode(segment) }.join("/")
      case provider
      when "github" then "#{repository_url}/blob/#{ERB::Util.url_encode(ref)}/#{encoded}"
      when "gitlab" then "#{repository_url}/-/blob/#{ERB::Util.url_encode(ref)}/#{encoded}"
      else
        kind = ref.match?(/\A\h{40}\z/) ? "commit" : "branch"
        "#{repository_url}/src/#{kind}/#{ERB::Util.url_encode(ref)}/#{encoded}"
      end
    end

    # Does a CI server URL (CI_SERVER_URL, GITHUB_SERVER_URL, JENKINS_URL, CI_SYSTEM_URL) point
    # at this connection's server? Scheme, host, port and path (sub-path) are compared.
    def same_server?(url)
      self.class.server_key(url) == self.class.server_key(effective_base_url)
    end

    # "https://GitLab.example.com:443/GitLab/" -> "https://gitlab.example.com/gitlab"
    def self.canonical_server(url)
      key = server_key(url)
      return url.to_s.strip.downcase.chomp("/") unless key

      scheme, host, port, path = key
      default_port = scheme == "https" ? 443 : 80
      "#{scheme}://#{host}#{":#{port}" unless port == default_port}#{path}"
    end

    def self.server_key(url)
      uri = URI.parse(url.to_s.strip)
      return nil unless uri.is_a?(URI::HTTP) && uri.host.present?

      [uri.scheme.downcase, uri.host.downcase, uri.port, uri.path.to_s.chomp("/").downcase]
    rescue URI::InvalidURIError
      nil
    end

    # --- trigger ("Run in CI") ------------------------------------------------------
    def effective_trigger_ref
      trigger_ref.presence || "main"
    end

    def workflow_provider?
      WORKFLOW_PROVIDERS.include?(provider)
    end

    # Settings missing for a trigger, as attribute names (empty = ready). Secrets are only
    # checked for presence; whether they are valid shows "Check connection" or the trigger.
    def trigger_missing
      return [] if inbound_only? # nothing is sent; the pipeline is started by hand

      missing = []
      missing << :workflow if workflow_provider? && workflow.blank?
      case provider
      when "gitlab" then missing << :trigger_token unless trigger_token_set?
      when "jenkins"
        missing << :ci_username if ci_username.blank? && !trigger_token_set?
        missing << :token if ci_username.present? && !token_set?
      else missing << :token unless token_set?
      end
      missing
    end

    def trigger_ready?
      trigger_missing.empty?
    end

    # --- provider helpers -----------------------------------------------------------
    def effective_base_url
      (base_url.presence || DEFAULT_BASE_URLS[provider]).to_s.chomp("/")
    end

    def repository_url
      case provider
      when "jenkins" then jenkins_job_url
      when "woodpecker" then "#{effective_base_url}/repos/#{repository}"
      else "#{effective_base_url}/#{repository}"
      end
    end

    def github?
      provider == "github"
    end

    def gitlab?
      provider == "gitlab"
    end

    def jenkins?
      provider == "jenkins"
    end

    def woodpecker?
      provider == "woodpecker"
    end

    # Gitea API (Gitea, Forgejo, Codeberg): /api/v1, "Authorization: token …".
    def gitea_api?
      %w[gitea forgejo codeberg].include?(provider)
    end

    def forgejo_api?
      %w[forgejo codeberg].include?(provider)
    end

    # Jenkins job URL: "qa/e2e" -> <base>/job/qa/job/e2e
    def jenkins_job_url
      segments = repository.to_s.split("/").map { |segment| "job/#{ERB::Util.url_encode(segment)}" }
      "#{effective_base_url}/#{segments.join('/')}"
    end

    def new_iteration?
      ingest_mode == "new_iteration"
    end

    def matches?(provider_name, repository_name)
      provider == provider_name.to_s.downcase && repository.casecmp?(repository_name.to_s.strip)
    end

    # --- repo-qualified automation references (0016) ----------------------------------
    # Qualifier name of this connection's references: reference_name, else the last segment of
    # the repository path ("my-org/shop" -> "shop", Jenkins "qa/e2e-shop" -> "e2e-shop"); for
    # Woodpecker (numeric repository id) the connection name.
    def reference_qualifier_name
      return reference_name if reference_name.present?

      base = woodpecker? ? name.to_s : repository.to_s.split("/").last.to_s
      base.gsub(/[^A-Za-z0-9_.-]+/, "-").gsub(/\A[^A-Za-z0-9]+|-+\z/, "").first(100).presence
    end

    # Reference qualifier names of the project's connections (lower case).
    def self.reference_names(project)
      where(project_id: project.id).to_a.filter_map { |c| c.reference_qualifier_name&.downcase }.uniq
    end

    # Connections whose qualifier name is +name+ (case-insensitive), active forges first.
    def self.for_reference_name(project, name)
      return [] if name.blank?

      where(project_id: project.id).order(:id).to_a
                                   .select { |c| c.reference_qualifier_name&.casecmp?(name) }
    end

    def self.lookup(project, value)
      return nil if value.blank?

      scope = where(project_id: project.id)
      (value.to_s.match?(/\A\d+\z/) && scope.find_by(id: value.to_i)) ||
        scope.where("LOWER(name) = ?", value.to_s.strip.downcase).first
    end

    # server_url (0015): the CI's own server URL. When given, a connection to another server
    # with the same provider and repository path (gitlab.com vs. a self-hosted GitLab) is not used.
    def self.detect(project, provider_name, repository_name, server_url: nil)
      return nil if provider_name.blank? || repository_name.blank?

      candidates = candidates(project, provider_name, repository_name)
      return candidates.first if server_key(server_url).nil?

      candidates.find { |connection| connection.same_server?(server_url) }
    end

    # Connections with this provider and repository path, on any server (0016: one per server).
    def self.candidates(project, provider_name, repository_name)
      return [] if provider_name.blank? || repository_name.blank?

      where(project_id: project.id, provider: provider_name.to_s.downcase)
        .where("LOWER(repository) = ?", repository_name.to_s.strip.downcase).order(:id).to_a
    end

    # OpenProject repository browser URL of a file (attached Repositories-module repository).
    # Setting.host_name holds host and path of the OpenProject installation.
    def scm_file_url(path, ref: nil)
      return nil unless scm_repository && scm_repository.project_id == project_id

      path = path.to_s.strip.delete_prefix("./").delete_prefix("/")
      return nil if path.blank? || path.include?("..")

      rev = ref.to_s.match?(/\A[\w.-]+\z/) ? ref.to_s : nil
      encoded = path.split("/").map { |segment| ERB::Util.url_encode(segment) }.join("/")
      base = "#{Setting.protocol}://#{Setting.host_name.to_s.chomp('/')}/projects/#{ERB::Util.url_encode(project.identifier)}/repository"
      rev ? "#{base}/revisions/#{ERB::Util.url_encode(rev)}/entry/#{encoded}" : "#{base}/entry/#{encoded}"
    end

    private

    def normalize
      self.name = name.to_s.strip
      self.repository = repository.to_s.strip.delete_prefix("/").delete_suffix("/").delete_suffix(".git")
      self.base_url = base_url.to_s.strip.chomp("/").presence
      self.base_url = nil if base_url == DEFAULT_BASE_URLS[provider]
      self.target_run_name = target_run_name.to_s.strip.presence
      self.workflow = workflow.to_s.strip.delete_prefix(".github/workflows/").delete_prefix(".gitea/workflows/")
                              .delete_prefix(".forgejo/workflows/").presence
      self.trigger_ref = trigger_ref.to_s.strip.presence
      self.ci_username = ci_username.to_s.strip.presence
      self.ca_certificate = ca_certificate.to_s.gsub("\r\n", "\n").strip.presence
      self.inbound_only = false if inbound_only.nil?
      self.reference_name = reference_name.to_s.strip.presence
      self.e2e_tests = e2e_tests.to_s.strip.presence || "auto"
      self.server_url = self.class.canonical_server(effective_base_url).first(512) if provider.present?
    end

    def repository_format
      format = REPOSITORY_FORMATS[provider]
      return if format.nil? || repository.blank? || repository.match?(format)

      errors.add(:repository, :invalid)
    end

    # The stored secrets are sent to effective_base_url ("Check connection", "Run in CI").
    # Pointing an existing connection at another server (or provider) without entering them
    # again would hand secrets someone else saved to a host of the editor's choice.
    def token_reentered_for_new_endpoint
      return if new_record?
      # A new CA changes which server the secrets are trusted to go to as much as a new URL.
      return unless will_save_change_to_base_url? || will_save_change_to_provider? || will_save_change_to_ca_certificate?

      if token_set? && !will_save_change_to_token_ciphertext?
        errors.add(:token, :reenter_for_new_endpoint)
      end
      if trigger_token_set? && !will_save_change_to_trigger_token_ciphertext?
        errors.add(:trigger_token, :reenter_for_new_endpoint)
      end
    end

    def scm_repository_of_project
      return if scm_repository_id.nil?

      errors.add(:scm_repository, :invalid) unless scm_repository && scm_repository.project_id == project_id
    end

    def base_url_format
      return if base_url.blank?

      # A path is fine (sub-path installations); query, fragment and credentials are not.
      uri = URI.parse(base_url)
      unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?
        errors.add(:base_url, :invalid)
      end
    rescue URI::InvalidURIError
      errors.add(:base_url, :invalid)
    end

    def ca_certificate_format
      return if ca_certificate.blank?

      if ca_certificate.bytesize > CA_MAX_BYTES
        errors.add(:ca_certificate, :too_long, count: CA_MAX_BYTES)
      elsif ca_certificate.include?("PRIVATE KEY")
        errors.add(:ca_certificate, :private_key)
      else
        pems = ca_certificate.scan(PEM_CERTIFICATE)
        # Text around the blocks ("subject=…" lines of a bundle) is ignored.
        if pems.empty? || pems.size > CA_MAX_CERTIFICATES
          errors.add(:ca_certificate, :pem, max: CA_MAX_CERTIFICATES)
        else
          pems.each { |pem| OpenSSL::X509::Certificate.new(pem) }
        end
      end
    rescue OpenSSL::X509::CertificateError
      errors.add(:ca_certificate, :pem, max: CA_MAX_CERTIFICATES)
    end
  end
end
