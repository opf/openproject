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

describe PlaceholderUser, type: :model do
  let(:placeholder_user) { FactoryBot.build(:placeholder_user) }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:member) do
    FactoryBot.build(:member, project: project,
                              roles: [role],
                              principal: placeholder_user)
  end
  let(:status) { FactoryBot.create(:status) }
  let(:issue) do
    FactoryBot.build(:work_package, type: project.types.first,
                                    author: placeholder_user,
                                    project: project,
                                    status: status)
  end

  subject { placeholder_user }

  describe '#name' do
    it 'updates the name' do
      subject.name = "Foo"
      expect(subject.name).to eq("Foo")
    end
    it 'updates the lastname attribute' do
      subject.name = "Foo"
      expect(subject.lastname).to eq("Foo")
    end
  end
end
