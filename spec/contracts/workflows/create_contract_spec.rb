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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Workflows::CreateContract do
  shared_let(:project) { create(:project) }

  subject(:contract) { described_class.new(Workflow.new(name: "Release flow"), user) }

  def base_errors
    contract.validate
    contract.errors.symbols_for(:base)
  end

  context "for an administrator" do
    let(:user) { create(:admin) }

    it "is valid" do
      expect(base_errors).to be_empty
    end
  end

  context "for a member who manages the project's variants" do
    let(:user) { create(:user, member_with_permissions: { project => %i[manage_project_variants] }) }

    it "refuses it" do
      expect(base_errors).to include(:error_unauthorized)
    end
  end

  context "for a user without permissions" do
    let(:user) { create(:user) }

    it "refuses it" do
      expect(base_errors).to include(:error_unauthorized)
    end
  end
end
