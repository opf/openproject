#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Repository < ApplicationRecord
  include Redmine::Ciphering
  include OpenProject::SCM::ManageableRepository

  belongs_to :project
  has_many :changesets, -> {
    order("#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC")
  }

  before_save :sanitize_urls

  # Managed repository lifetime
  after_create :create_managed_repository, if: Proc.new { |repo| repo.managed? }
  # Raw SQL to delete changesets and changes in the database
  # has_many :changesets, dependent: :destroy is too slow for big repositories
  before_destroy :clear_changesets
  after_destroy :delete_managed_repository, if: Proc.new { |repo| repo.managed? }

  validates :password, length: { maximum: 255, allow_nil: true }
  validate :validate_enabled_scm, on: :create

  def file_changes
    Change.where(changeset_id: changesets).joins(:changeset)
  end

  # Checks if the SCM is enabled when creating a repository
  def validate_enabled_scm
    errors.add(:type, :not_available) unless OpenProject::SCM::Manager.enabled?(vendor)
  end

  # Removes leading and trailing whitespace
  def url=(arg)
    write_attribute(:url, arg ? arg.to_s.strip : nil)
  end

  # Removes leading and trailing whitespace
  def root_url=(arg)
    write_attribute(:root_url, arg ? arg.to_s.strip : nil)
  end

  def password
    read_ciphered_attribute(:password)
  end

  def password=(arg)
    write_ciphered_attribute(:password, arg)
  end

  def scm_adapter
    self.class.scm_adapter_class
  end

  def scm
    @scm ||= scm_adapter.new(
      url, root_url,
      login, password, path_encoding,
      project.identifier
    )

    # override the adapter's root url with the full url
    # if none other was set.
    unless @scm.root_url.present?
      @scm.root_url = root_url.presence || url
    end

    @scm
  end

  def self.authorization_policy
    nil
  end

  def self.scm_config
    scm_adapter_class.config
  end

  def self.available_types
    supported_types - disabled_types
  end

  ##
  # Retrieves the :disabled_types setting from `configuration.yml
  # To avoid wrong set operations for string-based configuration, force them to symbols.
  def self.disabled_types
    (scm_config[:disabled_types] || []).map(&:to_sym)
  end

  def vendor
    self.class.vendor
  end

  delegate :supports_cat?, to: :scm

  delegate :supports_annotate?, to: :scm

  def supports_all_revisions?
    true
  end

  def supports_directory_revisions?
    false
  end

  def supports_checkout_info?
    true
  end

  def self.requires_checkout_base_url?
    true
  end

  def entry(path = nil, identifier = nil)
    scm.entry(path, identifier)
  end

  def entries(path = nil, identifier = nil, limit: nil)
    entries = scm.entries(path, identifier)

    if limit && limit < entries.size
      result = OpenProject::SCM::Adapters::Entries.new entries.take(limit)
      result.truncated = entries.size - result.size

      result
    else
      entries
    end
  end

  delegate :branches, to: :scm

  delegate :tags, to: :scm

  delegate :default_branch, to: :scm

  def properties(path, identifier = nil)
    scm.properties(path, identifier)
  end

  def cat(path, identifier = nil)
    scm.cat(path, identifier)
  end

  delegate :diff, to: :scm

  def diff_format_revisions(cs, cs_to, sep = ":")
    text = ""
    text << (cs_to.format_identifier + sep) if cs_to
    text << cs.format_identifier if cs
    text
  end

  # Returns a path relative to the url of the repository
  def relative_path(path)
    path
  end

  ##
  # Update the required storage information, when necessary.
  # Returns whether an asynchronous count refresh has been requested.
  def update_required_storage
    if scm.storage_available?
      oldest_cachable_time = Setting.repository_storage_cache_minutes.to_i.minutes.ago
      if storage_updated_at.nil? ||
         storage_updated_at < oldest_cachable_time

        ::SCM::StorageUpdaterJob.perform_later(self)
        return true
      end
    end

    false
  end

  # Finds and returns a revision with a number or the beginning of a hash
  def find_changeset_by_name(name)
    name = name.to_s
    return nil if name.blank?

    changesets.where((name.match?(/\A\d*\z/) ? ["revision = ?", name] : ["revision LIKE ?", name + "%"])).first
  end

  def latest_changeset
    @latest_changeset ||= changesets.first
  end

  # Returns the latest changesets for +path+
  # Default behaviour is to search in cached changesets
  def latest_changesets(path, _rev, limit = 10)
    if path.blank?
      changesets.includes(:user)
        .order("#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC")
        .limit(limit)
    else
      changesets.includes(changeset: :user)
        .where(["path = ?", path.with_leading_slash])
        .order("#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC")
        .limit(limit)
        .map(&:changeset)
    end
  end

  def scan_changesets_for_work_package_ids
    changesets.each(&:scan_comment_for_work_package_ids)
  end

  # Returns an array of committers usernames and associated user_id
  def committers
    @committers ||= Changeset.where(repository_id: id).distinct.pluck(:committer, :user_id)
  end

  # Maps committers username to a user ids
  def committer_ids=(h)
    if h.is_a?(Hash)
      committers.each do |committer, user_id|
        new_user_id = h[committer]
        if new_user_id && (new_user_id.to_i != user_id.to_i)
          new_user_id = (new_user_id.to_i > 0 ? new_user_id.to_i : nil)
          Changeset.where(["repository_id = ? AND committer = ?", id, committer])
            .update_all("user_id = #{new_user_id.nil? ? 'NULL' : new_user_id}")
        end
      end
      @committers = nil
      @found_committer_users = nil
      true
    else
      false
    end
  end

  # Returns the Redmine User corresponding to the given +committer+
  # It will return nil if the committer is not yet mapped and if no User
  # with the same username or email was found
  def find_committer_user(committer)
    if committer.present?
      @found_committer_users ||= {}
      return @found_committer_users[committer] if @found_committer_users.has_key?(committer)

      user = nil
      c = changesets.includes(:user).references(:users).find_by(committer:)
      if c && c.user
        user = c.user
      elsif committer.strip =~ /\A([^<]+)(<(.*)>)?\z/
        username = $1.strip
        email = $3
        u = User.by_login(username).first
        u ||= User.find_by_mail(email) if email.present?
        user = u
      end
      @found_committer_users[committer] = user
      user
    end
  end

  def repo_log_encoding
    encoding = log_encoding.to_s.strip
    encoding.presence || "UTF-8"
  end

  # Fetches new changesets for all repositories of active projects
  # Can be called periodically by an external script
  # eg. ruby script/runner "Repository.fetch_changesets"
  def self.fetch_changesets
    Project.active.has_module(:repository).includes(:repository).find_each do |project|
      if project.repository
        begin
          project.repository.fetch_changesets
        rescue OpenProject::SCM::Exceptions::CommandFailed => e
          logger.error "scm: error during fetching changesets: #{e.message}"
        end
      end
    end
  end

  # scan changeset comments to find related and fixed work packages for all repositories
  def self.scan_changesets_for_work_package_ids
    all.find_each(&:scan_changesets_for_work_package_ids)
  end

  ##
  # Builds a model instance of type +Repository::#{vendor}+ with the given parameters.
  #
  # @param [Project] project The project this repository belongs to.
  # @param [Symbol] vendor   The SCM vendor symbol (e.g., :git, :subversion)
  # @param [Hash] params     Custom parameters for this SCM as delivered from the repository
  #                          field.
  #
  # @param [Symbol] type     SCM tag to determine the type this repository should be built as
  #
  # @raise [OpenProject::SCM::RepositoryBuildError]
  #                                  Raised when the instance could not be built
  #                                  given the parameters.
  # @raise [::NameError] Raised when the given +vendor+ could not be resolved to a class.
  def self.build(project, vendor, params, type)
    klass = build_scm_class(vendor)

    # We can't possibly know the form fields this particular vendor
    # desires, so we allow it to filter them from raw params
    # before building the instance with it.
    args = klass.permitted_params(params)

    repository = klass.new(args)
    repository.attributes = args
    repository.project = project

    set_verified_type!(repository, type) unless type.nil?

    repository.configure(type, args)

    repository
  end

  ##
  # Build a temporary model instance of the given vendor for temporary use in forms.
  # Will not receive any args.
  def self.build_scm_class(vendor)
    klass = OpenProject::SCM::Manager.registered[vendor]

    if klass.nil?
      raise OpenProject::SCM::Exceptions::RepositoryBuildError.new(
        I18n.t("repositories.errors.disabled_or_unknown_vendor", vendor:)
      )
    else
      klass
    end
  end

  ##
  # Verifies that the chosen scm type can be selected
  def self.set_verified_type!(repository, type)
    if repository.class.available_types.include? type
      repository.scm_type = type
    else
      raise OpenProject::SCM::Exceptions::RepositoryBuildError.new(
        I18n.t("repositories.errors.disabled_or_unknown_type",
               type:,
               vendor: repository.vendor)
      )
    end
  end

  ##
  # Allow global permittible params. May be overridden by plugins
  def self.permitted_params(params)
    params.permit(:url)
  end

  def self.scm_adapter_class
    nil
  end

  def self.enabled?
    OpenProject::SCM::Manager.enabled?(vendor)
  end

  ##
  # Returns the SCM vendor symbol for this repository
  # e.g., Repository::Git => :git
  def self.vendor
    vendor_name.underscore.to_sym
  end

  ##
  # Returns the SCM vendor name for this repository
  # e.g., Repository::Git => Git
  def self.vendor_name
    name.demodulize
  end

  # Strips url and root_url
  def sanitize_urls
    url.strip! if url.present?
    root_url.strip! if root_url.present?
    true
  end

  def clear_changesets
    cs = Changeset.table_name
    ch = Change.table_name
    ci = "#{table_name_prefix}changesets_work_packages#{table_name_suffix}"
    self.class.connection.delete("DELETE FROM #{ch} WHERE #{ch}.changeset_id IN (SELECT #{cs}.id FROM #{cs} WHERE #{cs}.repository_id = #{id})")
    self.class.connection.delete("DELETE FROM #{ci} WHERE #{ci}.changeset_id IN (SELECT #{cs}.id FROM #{cs} WHERE #{cs}.repository_id = #{id})")
    self.class.connection.delete("DELETE FROM #{cs} WHERE #{cs}.repository_id = #{id}")
  end

  protected

  ##
  # Create local managed repository request when the built instance
  # is managed by OpenProject
  def create_managed_repository
    service = SCM::CreateManagedRepositoryService.new(self)
    if service.call
      true
    else
      raise OpenProject::SCM::Exceptions::RepositoryBuildError.new(
        service.localized_rejected_reason
      )
    end
  end

  ##
  # Destroy local managed repository request when the built instance
  # is managed by OpenProject
  def delete_managed_repository
    service = SCM::DeleteManagedRepositoryService.new(self)
    if service.call
      true
    else
      errors.add(:base, service.localized_rejected_reason)
      raise ActiveRecord::Rollback
    end
  end
end
