#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Shares
  class ModalBodyComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    include ApplicationHelper
    include MemberHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    attr_reader :entity,
                :shares,
                :available_roles,
                :sharing_manageable,
                :errors

    def initialize(entity:,
                   shares:,
                   available_roles:,
                   sharing_manageable:,
                   errors: nil)
      super

      @entity = entity
      @shares = shares
      @available_roles = available_roles
      @sharing_manageable = sharing_manageable
      @errors = errors
    end

    def self.wrapper_key
      "share_list"
    end

    private

    def project_scoped_entity?
      entity.respond_to?(:project)
    end

    def insert_target_modified?
      true
    end

    def insert_target_modifier_id
      "op-share-dialog-active-shares"
    end

    def blankslate_config # rubocop:disable Metrics/AbcSize
      @blankslate_config ||= {}.tap do |config|
        if params[:filters].blank?
          config[:icon] = :people
          config[:heading_text] = I18n.t("sharing.text_empty_state_header")
          config[:description_text] = I18n.t("sharing.text_empty_state_description", entity: @entity.class.model_name.human)
        else
          config[:icon] = :search
          config[:heading_text] = I18n.t("sharing.text_empty_search_header")
          config[:description_text] = I18n.t("sharing.text_empty_search_description")
        end
      end
    end

    def type_filter_options
      if project_scoped_entity?
        [
          { label: I18n.t("sharing.filter.project_member"),
            value: { principal_type: "User", project_member: true } },
          { label: I18n.t("sharing.filter.not_project_member"),
            value: { principal_type: "User", project_member: false } },
          { label: I18n.t("sharing.filter.project_group"),
            value: { principal_type: "Group", project_member: true } },
          { label: I18n.t("sharing.filter.not_project_group"),
            value: { principal_type: "Group", project_member: false } }
        ]
      else
        [
          { label: I18n.t("sharing.filter.user"), value: { principal_type: "User" } },
          { label: I18n.t("sharing.filter.group"), value: { principal_type: "Group" } }
        ]

      end
    end

    def type_filter_option_active?(_option)
      principal_type_filter_value = current_filter_value(params[:filters], "principal_type")
      project_member_filter_value = current_filter_value(params[:filters], "also_project_member")

      return false if principal_type_filter_value.nil? || project_member_filter_value.nil?

      principal_type_checked =
        _option[:value][:principal_type] == principal_type_filter_value
      membership_selected =
        _option[:value][:project_member] == ActiveRecord::Type::Boolean.new.cast(project_member_filter_value)

      principal_type_checked && membership_selected
    end

    def role_filter_option_active?(_option)
      role_filter_value = current_filter_value(params[:filters], "role_id")

      return false if role_filter_value.nil?

      selected_role = @available_roles.find { _1[:value] == _option[:value] }

      selected_role[:value] == role_filter_value.to_i
    end

    def filter_url(type_option: nil, role_option: nil)
      return url_for([@entity, Member]) if type_option.nil? && role_option.nil?

      args = {}
      filter = []

      filter += apply_role_filter(role_option)
      filter += apply_type_filter(type_option)

      args[:filters] = filter.to_json unless filter.empty?

      url_for([@entity, Member, args])
    end

    def apply_role_filter(option)
      current_role_filter_value = current_filter_value(params[:filters], "role_id")
      filter = []

      if option.nil? && current_role_filter_value.present?
        # When there is already a role filter set and no new value passed, we want to keep that filter
        filter = role_filter_for({ value: current_role_filter_value })
      elsif option.present? && !role_filter_option_active?(option)
        # Only when the passed filter option is not the currently selected one, we apply the filter
        filter = role_filter_for(option)
      end

      filter
    end

    def role_filter_for(option)
      [
        { role_id: { operator: "=", values: [option[:value]] } }
      ]
    end

    def apply_type_filter(_option)
      current_type_filter_value = current_filter_value(params[:filters], "principal_type")
      current_member_filter_value = current_filter_value(params[:filters], "also_project_member")
      filter = []

      if _option.nil? && current_type_filter_value.present? && current_member_filter_value.present?
        # When there is already a type filter set and no new value passed, we want to keep that filter
        value = { value: { principal_type: current_type_filter_value, project_member: current_member_filter_value } }
        filter = type_filter_for(value)
      elsif _option.present? && !type_filter_option_active?(_option)
        # Only when the passed filter option is not the currently selected one, we apply the filter
        filter = type_filter_for(_option)
      end

      filter
    end

    def type_filter_for(_option)
      filter = []
      if ActiveRecord::Type::Boolean.new.cast(_option[:value][:project_member])
        filter.push({ also_project_member: { operator: "=", values: [OpenProject::Database::DB_VALUE_TRUE] } })
      else
        filter.push({ also_project_member: { operator: "=", values: [OpenProject::Database::DB_VALUE_FALSE] } })
      end

      filter.push({ principal_type: { operator: "=", values: [_option[:value][:principal_type]] } })
      filter
    end

    def current_filter_value(filters, filter_key)
      return nil if filters.nil?

      given_filters = JSON.parse(filters).find { |key| key.key?(filter_key) }
      given_filters ? given_filters[filter_key]["values"].first : nil
    end
  end
end
