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

RSpec.shared_context "with queries contract" do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project) }
  let(:name) { "Some query name" }
  let(:public) { false }
  let(:user) { current_user }
  let(:permissions) { %i[save_queries] }
  let(:query) do
    build_stubbed(:query, project:, public:, user:, name:)
  end

  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project:) if project
    end
  end

  let(:contract) { described_class.new(query, current_user) }

  before do
    # Assume project is always visible
    allow(contract).to receive(:project_visible?).and_return true
  end

  describe "validation" do
    it_behaves_like "contract is valid"

    context "if the name is nil" do
      let(:name) { nil }

      it_behaves_like "contract is invalid", name: :blank
    end

    context "if the name is empty" do
      let(:name) { "" }

      it_behaves_like "contract is invalid", name: :blank
    end
  end

  include_examples "contract reuses the model errors"
end
