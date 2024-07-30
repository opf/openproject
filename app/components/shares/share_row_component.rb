# frozen_string_literal: true

# -- copyright
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
# ++

module Shares
  class ShareRowComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    VIRTUAL_SHARE_ID = "virtual-share-id"

    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(share:, strategy:, container: nil)
      super

      @share = share
      @strategy = strategy
      @entity = strategy.entity
      @principal = share.principal
      @available_roles = strategy.available_roles
      @container = container
    end

    def wrapper_uniq_by
      share.id
    end

    private

    attr_reader :share, :entity, :principal, :container, :available_roles, :strategy

    def share_editable?
      @share_editable ||= User.current != share.principal && sharing_manageable?
    end

    def sharing_manageable?
      strategy.manageable?
    end

    def grid_css_classes
      if sharing_manageable?
        "op-share-dialog-modal-body--user-row_manageable"
      else
        "op-share-dialog-modal-body--user-row"
      end
    end

    def select_share_checkbox_options
      {
        name: "share_ids",
        value: share.id,
        scheme: :array,
        label: principal.name,
        visually_hide_label: true
      }
    end
  end
end
