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

module WorkPackageTypes
  class SettingsComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(model, copy_workflow_from: nil, **)
      @copy_workflow_from = copy_workflow_from
      super(model, **)
    end

    def form_options
      if model.new_record?
        create_form_options
      else
        update_form_options
      end
    end

    private

    attr_reader :copy_workflow_from

    def create_form_options
      { url: types_path, method: :post, model:, copy_workflow_from:, data: core_settings_toggle_data }
    end

    def update_form_options
      { url: type_settings_path(type_id: model.id), method: :patch, model:, data: core_settings_toggle_data }
    end

    def core_settings_toggle_data
      {
        controller: "admin--work-package-type-settings",
        "admin--work-package-type-settings-inherited-value": model.subtype?
      }
    end
  end
end
