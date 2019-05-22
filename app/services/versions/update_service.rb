#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Versions
  class UpdateService
    include Concerns::Contracted

    attr_reader :user,
                :version

    def initialize(user:, version:)
      @user = user
      @version = version
      self.contract_class = Versions::UpdateContract
    end

    def call(params)
      attributes_call = set_attributes(params)

      Version.transaction do
        if attributes_call.failure?
          # nothing to do
        elsif !attributes_call.result.save
          attributes_call.errors = attributes_call.result.errors
          attributes_call.success = false
        else
          after_save
        end
      end

      attributes_call
    end

    private

    def set_attributes(params)
      SetAttributesService
        .new(user: user,
             version: version,
             contract_class: contract_class)
        .call(params)
    end

    def after_save
      version.touch if only_custom_values_updated?
      update_wps_from_sharing_change if version.saved_change_to_sharing?
    end

    # Update the issue's fixed versions. Used if a version's sharing changes.
    def update_wps_from_sharing_change
      if no_valid_version_before_or_now? ||
         sharing_now_less_broad?
        WorkPackage.update_versions_from_sharing_change version
      end
    end

    def only_custom_values_updated?
      version.saved_changes.empty? && version.custom_values.map(&:saved_changes).any?(&:present?)
    end

    def no_valid_version_before_or_now?
      version_sharings.index(version.sharing_before_last_save).nil? ||
        version_sharings.index(version.sharing).nil?
    end

    def sharing_now_less_broad?
      version_sharings.index(version.sharing_before_last_save) > version_sharings.index(version.sharing)
    end

    def version_sharings
      Version::VERSION_SHARINGS
    end
  end
end
