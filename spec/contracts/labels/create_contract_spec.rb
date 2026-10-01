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
require_relative "shared_contract_examples"

RSpec.describe Labels::CreateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }

  let(:label) { build(:label) }
  let(:contract) { described_class.new(label, current_user) }

  it_behaves_like "label contract" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[edit_work_packages] })
    end
  end

  context "when admin" do
    let(:current_user) { create(:admin) }

    it_behaves_like "contract is valid"
  end

  context "when member without edit_work_packages permission" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it_behaves_like "contract user is unauthorized"
  end

  include_examples "contract reuses the model errors" do
    let(:current_user) { create(:admin) }
  end
end
