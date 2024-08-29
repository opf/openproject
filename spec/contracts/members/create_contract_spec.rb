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
require_relative "shared_contract_examples"

RSpec.describe Members::CreateContract do
  include_context "ModelContract shared context"

  it_behaves_like "member contract" do
    let(:member) do
      Member.new(project: member_project,
                 roles: member_roles,
                 principal: member_principal)
    end

    let(:contract) { described_class.new(member, current_user) }

    describe "#validation" do
      context "if the principal is nil" do
        let(:member_principal) { nil }

        it_behaves_like "contract is invalid", principal: :blank
      end

      context "if the principal is a builtin user" do
        let(:member_principal) { build_stubbed(:anonymous) }

        it_behaves_like "contract is invalid", principal: :unassignable
      end

      context "if the principal is a locked user" do
        let(:member_principal) { build_stubbed(:locked_user) }

        it_behaves_like "contract is invalid", principal: :unassignable
      end
    end

    describe "#assignable_projects" do
      context "as a user without permission" do
        let(:current_user) { build_stubbed(:user) }

        it "is empty" do
          expect(contract.assignable_projects).to be_empty
        end
      end

      context "as a user with permission in one project" do
        let!(:project1) { create(:project) }
        let!(:project2) { create(:project) }
        let(:current_user) do
          create(:user,
                 member_with_permissions: { project1 => %i[manage_members] })
        end

        it "returns the one project" do
          expect(contract.assignable_projects.to_a).to eq [project1]
        end
      end
    end
  end
end
