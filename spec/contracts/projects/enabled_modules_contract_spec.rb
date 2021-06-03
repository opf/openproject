#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'contracts/shared/model_contract_shared_context'

describe Projects::EnabledModulesContract do
  include_context 'ModelContract shared context'

  let(:project) { FactoryBot.build_stubbed(:project, enabled_module_names: enabled_modules) }
  let(:contract) { described_class.new(project, current_user) }
  let(:ac_modules) { [{ name: :a_module, dependencies: %i[b_module] }] }
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |user|
      allow(user)
        .to receive(:allowed_to?) do |requested_permission, requested_project|
        permissions.include?(requested_permission) && requested_project == project
      end
    end
  end
  let(:enabled_modules) { %i[a_module b_module] }
  let(:permissions) { %i[select_project_modules] }

  before do
    allow(OpenProject::AccessControl)
      .to receive(:modules)
      .and_return(ac_modules)
  end

  describe '#valid?' do
    it_behaves_like 'contract is valid'

    context 'when the dependencies are not met' do
      let(:enabled_modules) { %i[a_module] }

      it_behaves_like 'contract is invalid', enabled_modules: :dependency_missing
    end

    context 'when the user lacks the select_project_modules permission' do
      let(:permissions) { %i[] }

      it_behaves_like 'contract is invalid', base: :error_unauthorized
    end
  end
end
