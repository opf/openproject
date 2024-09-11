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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Projects::EnabledModulesContract do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project, enabled_module_names: enabled_modules) }
  let(:enabled_modules) { %i[a_module b_module] }
  let(:permissions) { %i[select_project_modules] }
  let(:contract) { described_class.new(project, current_user) }
  let(:ac_modules) { [{ name: :a_module, dependencies: %i[b_module] }] }

  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project:
    end

    allow(OpenProject::AccessControl).to receive(:modules).and_return(ac_modules)
    allow(I18n).to receive(:t).with("project_module_a_module").and_return("A Module")
    allow(I18n).to receive(:t).with("project_module_b_module").and_return("B Module")
  end

  describe "#valid?" do
    it_behaves_like "contract is valid"

    context "when the dependencies are not met" do
      let(:enabled_modules) { %i[a_module] }

      it_behaves_like "contract is invalid", enabled_modules: :dependency_missing
    end

    context "when the user lacks the select_project_modules permission" do
      let(:permissions) { %i[] }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end
end
