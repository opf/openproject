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
require_relative "../shared_expectations"

RSpec.describe Automations::Conditions::Role do
  it_behaves_like "associated custom condition" do
    let(:key) { :role }

    describe "#allowed_values" do
      it "is the list of all roles" do
        roles = [build_stubbed(:project_role),
                 build_stubbed(:project_role)]

        allow(Role).to receive_messages(givable: Role, select: roles)

        expect(instance.allowed_values)
          .to eql([{ value: roles.first.id, label: roles.first.name },
                   { value: roles.last.id, label: roles.last.name }])
      end
    end

    describe "#fulfilled_by?" do
      let(:project) { instance_double(Project, id: 1) }
      let(:work_package) { instance_double(WorkPackage, project:, project_id: 1) }
      let(:user) do
        instance_double(User, id: 3).tap do |user|
          allow(user)
            .to receive(:roles_for_project)
            .with(project)
            .and_return(roles)
        end
      end
      let(:role1) { instance_double(Role, id: 1) }
      let(:role2) { instance_double(Role, id: 2) }
      let(:roles) { [role1, role2] }

      it "is true if values are empty" do
        instance.values = []

        expect(instance)
          .to be_fulfilled_by(work_package, user)
      end

      it "is true if values the id of roles the user has in the work package's project" do
        instance.values = [1]

        expect(instance)
          .to be_fulfilled_by(work_package, user)
      end

      it "is false if values do not include work package's status_id" do
        instance.values = [5]

        expect(instance)
          .not_to be_fulfilled_by(work_package, user)
      end
    end
  end
end
