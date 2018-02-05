#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'
require_relative '../shared_expectations'

describe CustomActions::Conditions::Role, type: :model do
  it_behaves_like 'associated custom condition' do
    let(:key) { :role }

    describe '#allowed_values' do
      it 'is the list of all roles' do
        roles = [FactoryGirl.build_stubbed(:role),
                 FactoryGirl.build_stubbed(:role)]

        allow(Role)
          .to receive_message_chain(:givable, :select)
          .and_return(roles)

        expect(instance.allowed_values)
          .to eql([{ value: nil, label: '-' },
                   { value: roles.first.id, label: roles.first.name },
                   { value: roles.last.id, label: roles.last.name }])
      end
    end

    describe '#fulfilled_by?' do
      let(:work_package) { double('work_package', project_id: 1) }
      let(:user) { double('user', id: 3) }

      before do
        role1 = double('role', id: 1)
        role2 = double('role', id: 2)
        roles = [role1, role2]

        allow(Role)
          .to receive(:joins)
          .with(:members)
          .and_return(roles)
        allow(roles)
          .to receive(:where)
          .with(members: { project_id: [work_package.project_id],
                           user_id: user.id })
          .and_return(roles)
        allow(roles)
          .to receive(:select)
          .and_return(roles)
      end

      it 'is true if values are empty' do
        instance.values = []

        expect(instance.fulfilled_by?(work_package, user))
          .to be_truthy
      end

      it "is true if values the id of roles the user has in the work package's project" do
        instance.values = [1]

        expect(instance.fulfilled_by?(work_package, user))
          .to be_truthy
      end

      it "is false if values do not include work package's status_id" do
        instance.values = [5]

        expect(instance.fulfilled_by?(work_package, user))
          .to be_falsey
      end
    end
  end
end
