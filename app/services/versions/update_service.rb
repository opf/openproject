#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Versions
  class UpdateService < ::BaseServices::Update
    private

    def after_perform(service_call)
      model.touch if only_custom_values_updated?
      update_wps_from_sharing_change if model.saved_change_to_sharing?
      service_call
    end

    # Update the issue's versions. Used if a version's sharing changes.
    def update_wps_from_sharing_change
      if no_valid_version_before_or_now? ||
         sharing_now_less_broad?
        WorkPackage.update_versions_from_sharing_change model
      end
    end

    def only_custom_values_updated?
      !model.saved_changes? && model.custom_values.any?(&:saved_changes?)
    end

    def no_valid_version_before_or_now?
      version_sharings.index(model.sharing_before_last_save).nil? ||
        version_sharings.index(model.sharing).nil?
    end

    def sharing_now_less_broad?
      version_sharings.index(model.sharing_before_last_save) > version_sharings.index(model.sharing)
    end

    def version_sharings
      Version::VERSION_SHARINGS
    end
  end
end
