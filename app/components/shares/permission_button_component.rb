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

module Shares
  class PermissionButtonComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(share:, strategy:, **system_arguments)
      super

      @strategy = strategy
      @share = share
      @system_arguments = system_arguments
    end

    # Switches the component to either update the share directly (by sending a PATCH to the share path)
    # or be passive and work like a select inside a form.
    def update_path
      if share.persisted?
        url_for([share.entity, share])
      end
    end

    def role_active?(role_hash)
      role_hash[:value] == active_role.id
    end

    def wrapper_uniq_by
      share.id || @system_arguments.dig(:data, :"test-selector")
    end

    private

    attr_reader :share, :strategy

    def active_role
      if share.persisted?
        share.roles
             .merge(MemberRole.only_non_inherited)
             .first
      else
        share.roles.first
      end
    end

    def permission_name(value)
      strategy.available_roles.find { |role_hash| role_hash[:value] == value }[:label]
    end

    def form_inputs(role_id)
      [].tap do |inputs|
        inputs << { name: "role_ids[]", value: role_id }
        inputs << { name: "filters", value: params[:filters] } if params[:filters]
      end
    end

    def tooltip_message
      return if strategy.manageable?

      I18n.t("sharing.denied", entities: strategy.entity.class.model_name.human(count: 2))
    end

    def tooltip_wrapper_classes
      return [] if strategy.manageable?

      ["tooltip--left"]
    end

    def editable?
      strategy.manageable? && share.principal != User.current
    end
  end
end
