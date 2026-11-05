# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  class CiConnection < ApplicationRecord
    self.table_name = "tm_ci_connections"
    self.filter_attributes += %i[token_ciphertext]

    PROVIDERS = %w[github].freeze
    INGEST_MODES = %w[new_run new_iteration].freeze
    DEFAULT_BASE_URLS = { "github" => "https://api.github.com" }.freeze
    OWNER_REPO = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\z}
    REPOSITORY_FORMATS = { "github" => OWNER_REPO }.freeze
    WORKFLOW_FORMAT = /\A[A-Za-z0-9_.-]+\.ya?ml\z/
    REF_FORMAT = %r{\A[A-Za-z0-9_./-]+\z}

    belongs_to :project
    belongs_to :created_by, class_name: "User", optional: true
    has_many :test_runs, class_name: "TestManagement::TestRun", foreign_key: :connection_id,
                         inverse_of: :connection, dependent: :nullify
    has_many :iterations, class_name: "TestManagement::TestRunIteration", foreign_key: :connection_id,
                          inverse_of: :connection, dependent: :nullify

    before_validation :normalize

    validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :project_id, case_sensitive: false }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :repository, presence: true, length: { maximum: 255 },
                           uniqueness: { scope: %i[project_id provider], case_sensitive: false }
    validates :ingest_mode, inclusion: { in: INGEST_MODES }
    validates :target_run_name, length: { maximum: 255 }
    validates :target_run_name, presence: true, if: -> { ingest_mode == "new_iteration" }
    validates :workflow, :trigger_ref, length: { maximum: 255 }
    validates :workflow, format: { with: WORKFLOW_FORMAT }, allow_blank: true
    validates :trigger_ref, format: { with: REF_FORMAT }, allow_blank: true
    validate :repository_format

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(Arel.sql("LOWER(tm_ci_connections.name)"), :id) }

    # Write-only: the readers exist because contracts and form builders read every declared attribute.
    def token = nil

    def remove_token = nil

    def token=(value)
      return if value.blank?

      self.token_ciphertext = CiTokenCipher.encrypt(value.to_s.strip)
      self.token_updated_at = Time.current
    end

    def remove_token=(value)
      return unless ActiveModel::Type::Boolean.new.cast(value)

      self.token_ciphertext = nil
      self.token_updated_at = Time.current
    end

    def token_set?
      token_ciphertext.present?
    end

    def decrypted_token
      CiTokenCipher.decrypt(token_ciphertext)
    end

    def token_readable?
      token_set? && decrypted_token.present?
    end

    def serializable_hash(options = nil)
      options = (options || {}).dup
      options[:except] = Array(options[:except]) + %w[token_ciphertext]
      super
    end

    def effective_base_url
      DEFAULT_BASE_URLS[provider].to_s
    end

    def repository_url
      "https://github.com/#{repository}"
    end

    def effective_trigger_ref
      trigger_ref.presence || "main"
    end

    def trigger_missing
      missing = []
      missing << :workflow if workflow.blank?
      missing << :token unless token_set?
      missing
    end

    def trigger_ready?
      trigger_missing.empty?
    end

    def new_iteration?
      ingest_mode == "new_iteration"
    end

    def matches?(provider_name, repository_name)
      provider == provider_name.to_s.downcase && repository.casecmp?(repository_name.to_s.strip)
    end

    def self.lookup(project, value)
      return nil if value.blank?

      scope = where(project_id: project.id)
      (value.to_s.match?(/\A\d+\z/) && scope.find_by(id: value.to_i)) ||
        scope.where("LOWER(name) = ?", value.to_s.strip.downcase).first
    end

    def self.detect(project, provider_name, repository_name)
      return nil if provider_name.blank? || repository_name.blank?

      where(project_id: project.id, provider: provider_name.to_s.downcase)
        .find_by("LOWER(repository) = ?", repository_name.to_s.strip.downcase)
    end

    private

    def normalize # rubocop:disable Metrics/AbcSize
      self.name = name.to_s.strip
      self.repository = repository.to_s.strip.delete_prefix("/").delete_suffix("/").delete_suffix(".git")
      self.target_run_name = target_run_name.to_s.strip.presence
      self.workflow = workflow.to_s.strip.delete_prefix(".github/workflows/").presence
      self.trigger_ref = trigger_ref.to_s.strip.presence
    end

    def repository_format
      format = REPOSITORY_FORMATS[provider]
      return if format.nil? || repository.blank? || repository.match?(format)

      errors.add(:repository, :invalid)
    end
  end
end
