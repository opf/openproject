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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Boards::CreateContract do
  include_context "ModelContract shared context"
  let(:project) { build_stubbed(:project) }
  let(:name) { "My Board" }
  let(:user) { build_stubbed(:user) }
  let(:grid) do
    build_stubbed(:board_grid, project:, name:)
  end
  let(:contract) { described_class.new(grid, user) }

  context "when :project not provided" do
    let(:project) { nil }

    it_behaves_like "contract is invalid", project: :blank
  end

  context "when :name not provided" do
    let(:name) { nil }

    it_behaves_like "contract is invalid", name: :blank
  end

  include_examples "contract reuses the model errors"
end
