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

# frozen_string_literal: true

module OpenProject
  module TypeSchemes
    require "open_project/type_schemes/engine"

    PATCH_TARGETS = {
      "WorkPackages::BaseContract" => %i[assignable_types validate_enabled_type],
      "WorkPackages::SetAttributesService" => %i[assign_default_type]
    }.freeze

    def self.assert_patch_targets!
      PATCH_TARGETS.each do |class_name, methods|
        klass = class_name.constantize
        missing = methods.reject do |name|
          klass.method_defined?(name) || klass.private_method_defined?(name)
        end
        next if missing.empty?

        raise "openproject-type_schemes patches #{class_name}##{missing.join(', #')}, which core no longer defines"
      end
    end
  end
end
