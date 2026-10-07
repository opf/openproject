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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Settings
  class UpdateParamsContract < ::ParamsContract
    include RequiresAdminGuard

    validate :journal_aggregation_time_minutes_is_within_bounds
    validate :restricted_password_login_requires_sso_provider
    validate :start_of_week_and_first_week_of_year_are_set_together
    validate :mail_from_is_an_email
    validate :default_projects_modules_include_dependencies
    validate :enforced_start_and_end_times_are_allowed

    protected

    def journal_aggregation_time_minutes_is_within_bounds
      value = params[:journal_aggregation_time_minutes]
      return if value.nil?

      allowed = Settings::Definition[:journal_aggregation_time_minutes].allowed
      unless allowed.cover?(value.to_i)
        errors.add :base, :journal_aggregation_time_minutes_is_out_of_bounds, min: allowed.min, max: allowed.max
      end
    end

    def restricted_password_login_requires_sso_provider
      return unless params[:password_login].in?([Users::PasswordLogin::EXCEPT_SSO, Users::PasswordLogin::NONE])
      return if Users::PasswordLogin.omniauth_configured?

      errors.add :base, :password_login_requires_sso_provider
    end

    def enforced_start_and_end_times_are_allowed
      allowed = ActiveRecord::Type::Boolean.new.cast(params[:allow_tracking_start_and_end_times])
      enforced = ActiveRecord::Type::Boolean.new.cast(params[:enforce_tracking_start_and_end_times])

      errors.add :base, I18n.t("setting_enforce_without_allow") if enforced && !allowed
    end

    def default_projects_modules_include_dependencies
      enabled_modules = Array(params[:default_projects_modules]).compact_blank.map(&:to_sym)

      OpenProject::AccessControl.modules.each do |project_module|
        next unless enabled_modules.include?(project_module[:name])
        next if (Array(project_module[:dependencies]) - enabled_modules).empty?

        errors.add :base, missing_module_dependencies_message(project_module)
      end
    end

    def missing_module_dependencies_message(project_module)
      I18n.t("settings.projects.missing_dependencies",
             module: I18n.t("project_module_#{project_module[:name]}"),
             dependencies: project_module[:dependencies].map { I18n.t("project_module_#{it}") }.join(", "))
    end

    def mail_from_is_an_email
      return unless params.key?(:mail_from)
      return if ::EmailValidator.valid?(params[:mail_from])

      errors.add :base, "#{I18n.t(:setting_mail_from)} #{I18n.t('activerecord.errors.messages.email')}"
    end

    def start_of_week_and_first_week_of_year_are_set_together
      return unless params.key?(:start_of_week) || params.key?(:first_week_of_year)
      return unless params[:start_of_week].present? ^ params[:first_week_of_year].present?

      errors.add :base,
                 I18n.t("settings.date_format.first_date_of_week_and_year_set",
                        first_week_setting_name: I18n.t(:setting_first_week_of_year),
                        day_of_week_setting_name: I18n.t(:setting_start_of_week))
    end
  end
end
