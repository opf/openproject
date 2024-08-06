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

require "spec_helper"

RSpec.describe Actions::Scopes::Default do
  subject(:scope) { Action.default }

  describe ".default" do
    let(:expected) do
      # This complicated and programmatic way is chosen so that the test can deal with additional actions being defined
      format_action = ->(namespace, action, permission, global, module_name) do
        standardized_namespace = API::Utilities::PropertyNameConverter.from_ar_name(namespace.to_s.singularize)
                                                                      .pluralize
                                                                      .underscore
        ["#{standardized_namespace}/#{action}",
         permission.to_s,
         global,
         module_name&.to_s]
      end

      OpenProject::AccessControl
        .contract_actions_map
        .flat_map do |permission, values|
          values[:actions].flat_map do |namespace, actions|
            actions.map do |action|
              format_action.call(namespace,
                                 action,
                                 permission,
                                 values[:global],
                                 values[:module_name])
            end
          end
        end
    end

    it "contains all actions" do
      expect(scope.pluck(:id, :permission, :global, :module))
        .to match_array(expected)
    end
  end
end
