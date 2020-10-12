#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'

describe ::API::Decorators::Single do
  let(:user) { FactoryBot.build(:user, member_in_project: project, member_through_role: role) }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:model) { Object.new }

  let(:single) { ::API::Decorators::Single.new(model, current_user: user) }

  it 'should authorize for a given permission' do
    expect(single.current_user_allowed_to(:view_work_packages, context: project)).to be_truthy
  end

  context 'unauthorized user' do
    let(:permissions) { [] }

    it 'should not authorize unauthorized user' do
      expect(single.current_user_allowed_to(:view_work_packages, context: project)).to be_falsey
    end
  end

  describe '.checked_permissions' do
    let(:permissions) { [:add_work_packages] }
    let!(:initial_value) { described_class.checked_permissions }

    it 'stores the value' do
      expect(described_class.checked_permissions).to be_nil

      described_class.checked_permissions = permissions

      expect(described_class.checked_permissions).to match_array permissions
    end

    after do
      described_class.checked_permissions = initial_value
    end
  end
end
