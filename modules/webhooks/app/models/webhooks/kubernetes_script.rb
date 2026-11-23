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

module Webhooks
  class KubernetesScript < ApplicationRecord
    ENVIRONMENT_VARIABLE_NAME = /\A[A-Za-z_][A-Za-z0-9_]*\z/
    RESERVED_ENVIRONMENT_PREFIX = "OP_"

    belongs_to :kubernetes_connection, class_name: "::Webhooks::KubernetesConnection"
    belongs_to :project_role, class_name: "::ProjectRole", optional: true
    belongs_to :global_role, class_name: "::GlobalRole", optional: true
    has_many :project_scripts, class_name: "::Webhooks::KubernetesProjectScript", dependent: :destroy
    has_many :projects, through: :project_scripts
    has_many :runs, class_name: "::Webhooks::KubernetesScriptRun", dependent: :delete_all
    has_one :service_account_association, as: :service, dependent: :destroy
    has_one :service_account, through: :service_account_association
    has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :image, :command, :body, presence: true
    validates :timeout_seconds, numericality: { only_integer: true, greater_than: 0 }
    validate :validate_input_schema, :validate_ui_schema, :validate_environment_variables

    after_create :ensure_api_identity!
    after_update :rename_api_identity, if: :saved_change_to_name?
    before_destroy :lock_service_account, prepend: true
    after_destroy :destroy_roles

    def ensure_api_identity!
      transaction do
        unless service_account
          account = ServiceAccount.create!(name: service_account_name, status: :active)
          create_service_account_association!(service_account: account)
          reload_service_account
        end

        oauth_application || create_oauth_application!(
          name: service_account_name,
          redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
          scopes: "api_v3",
          confidential: true,
          client_credentials_user_id: service_account.id,
          owner: service_account
        )
      end
    end

    def ensure_roles!
      transaction do
        self.project_role ||= ::ProjectRole.create!(name: service_account_name)
        self.global_role ||= ::GlobalRole.create!(name: global_role_name)
        save! if changed?
      end
      { project: project_role, global: global_role }
    end

    def issue_access_token!(project:, expires_in:)
      ensure_api_identity!
      project_script = project_scripts.find_by(project:) or raise "Script is not enabled in project #{project&.id}"
      ::Doorkeeper::AccessToken.create!(
        application: oauth_application,
        resource_owner_id: project_script.ensure_identity!.id,
        scopes: "api_v3",
        expires_in:
      )
    end

    def global_role_name
      I18n.t("webhooks.kubernetes.scripts.global_role_name", name: service_account_name)
    end

    def service_account_name
      I18n.t("webhooks.kubernetes.scripts.service_account_name",
             name: name.to_s.gsub(User::INVALID_NAME_REGEX, " ").squish)
    end

    def self.for_event(event_name, project_id)
      joins(:project_scripts)
        .where(webhooks_kubernetes_project_scripts: { project_id: })
        .where("? = ANY(event_names)", event_name)
    end

    def self.manual_for(work_package)
      where(manual: true)
        .joins(:project_scripts)
        .where(webhooks_kubernetes_project_scripts: { project_id: work_package.project_id })
        .where("cardinality(type_ids) = 0 OR ? = ANY(type_ids)", work_package.type_id)
        .order(:name)
    end

    def event_names=(names)
      super(Array(names).compact_blank)
    end

    def type_ids=(ids)
      super(Array(ids).compact_blank.map(&:to_i))
    end

    %i[input_schema ui_schema].each do |attribute|
      define_method(:"#{attribute}=") do |value|
        json_texts.delete(attribute)
        json_parse_errors.delete(attribute)
        if value.is_a?(String)
          json_texts[attribute] = value
          value = value.blank? ? nil : JSON.parse(value)
        end
        super(value)
      rescue JSON::ParserError => e
        json_parse_errors[attribute] = e.message
      end

      define_method(:"#{attribute}_text") do
        json_texts[attribute] || (self[attribute] && JSON.pretty_generate(self[attribute])) || ""
      end
    end

    # Rows submitted from the admin form. A row with an empty value keeps the stored value of that name,
    # rows that are not submitted are removed.
    def environment_variable_rows=(rows)
      rows = rows.values if rows.respond_to?(:each_pair)
      @environment_variable_rows = Array(rows).filter_map { environment_variable_row(it) }
      self.environment_variables = @environment_variable_rows.to_h { [it[:name], it[:value]] }
    end

    def environment_variable_names
      environment_variables.keys
    end

    # Values are only part of a row if they are not saved yet, so that saved values never reach the browser.
    def environment_variable_form_rows
      saved = attribute_in_database(:environment_variables) || {}
      rows = @environment_variable_rows || environment_variables.sort.map { |name, value| { name:, value: } }
      rows.map { |row| saved.key?(row[:name]) ? { name: row[:name], saved: true } : row.merge(saved: false) }
    end

    def form_schema
      ::JsonForms::Schema.new(input_schema)
    end

    def label
      button_label.presence || name
    end

    private

    def json_texts
      @json_texts ||= {}
    end

    def json_parse_errors
      @json_parse_errors ||= {}
    end

    def validate_input_schema
      json_parse_errors.each { |attribute, message| errors.add(attribute, :invalid_json, message:) }
      return if json_parse_errors.key?(:input_schema) || input_schema.blank?

      form_schema.errors.each { |message| errors.add(:base, message) }
    end

    def validate_ui_schema
      return if json_parse_errors.key?(:ui_schema) || ui_schema.blank?

      errors.add(:ui_schema, :invalid) unless ui_schema.is_a?(Hash) && ui_schema["type"].present?
    end

    def environment_variable_row(row)
      name = row[:name].to_s.strip
      { name:, value: row[:value].to_s.presence || environment_variables[name] } if name.present?
    end

    def validate_environment_variables
      Array(@environment_variable_rows).group_by { it[:name] }.each do |name, rows|
        error = environment_variable_error(name, rows)
        errors.add(:base, :"environment_variable_#{error}", name:, prefix: RESERVED_ENVIRONMENT_PREFIX) if error
      end
    end

    def environment_variable_error(name, rows)
      if !ENVIRONMENT_VARIABLE_NAME.match?(name) then :invalid_name
      elsif name.upcase.start_with?(RESERVED_ENVIRONMENT_PREFIX) then :reserved_name
      elsif rows.many? then :duplicate_name
      elsif rows.first[:value].blank? then :missing_value
      end
    end

    def rename_api_identity
      service_account&.update!(name: service_account_name)
      oauth_application&.update!(name: service_account_name)
      project_role&.update!(name: service_account_name)
      global_role&.update!(name: global_role_name)
      project_scripts.includes(:project).find_each(&:ensure_identity!)
    end

    def destroy_roles
      ::Role.where(id: [project_role_id, global_role_id].compact).destroy_all
    end

    # The account is kept (locked) so that journals created through the API stay attributed to it.
    def lock_service_account
      service_account&.update_column(:status, User.statuses[:locked])
    end
  end
end
