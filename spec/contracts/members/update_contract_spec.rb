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

RSpec.describe Members::UpdateContract do
  include_context "ModelContract shared context"

  it_behaves_like "member contract" do
    let(:member) do
      build_stubbed(:member,
                    project: member_project,
                    roles: member_roles,
                    principal: member_principal)
    end

    let(:contract) { described_class.new(member, current_user) }

    describe "validation" do
      context "if the principal is changed" do
        before do
          member.principal = build_stubbed(:user)
        end

        it_behaves_like "contract is invalid", user_id: :error_readonly
      end

      context "if the project is changed" do
        before do
          member.project = build_stubbed(:project)
        end

        it_behaves_like "contract is invalid", project_id: :error_readonly
      end

      context "if the principal is a locked user" do
        let(:member_principal) { build_stubbed(:locked_user) }

        it_behaves_like "contract is valid"
      end
    end
  end
end
