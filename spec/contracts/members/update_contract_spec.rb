#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative './shared_contract_examples'

describe Members::UpdateContract do
  it_behaves_like 'member contract' do
    let(:member) do
      FactoryBot.build_stubbed(:member,
                               project: member_project,
                               roles: member_roles,
                               principal: member_principal)
    end

    subject(:contract) { described_class.new(member, current_user) }

    describe 'validation' do
      context 'if the principal is changed' do
        before do
          member.principal = FactoryBot.build_stubbed(:user)
        end

        it 'is invalid' do
          expect_valid(false, user_id: %i(error_readonly))
        end
      end

      context 'if the project is changed' do
        before do
          member.project = FactoryBot.build_stubbed(:project)
        end

        it 'is invalid' do
          expect_valid(false, project_id: %i(error_readonly))
        end
      end

      context 'if the principal is a locked user' do
        let(:member_principal) { FactoryBot.build_stubbed(:locked_user) }

        it 'is valid' do
          expect_valid(true)
        end
      end
    end
  end
end
