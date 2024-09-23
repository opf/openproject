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

RSpec.describe Queries::WorkPackages::Filter::PrincipalLoader do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }
  let(:placeholder_user) { build_stubbed(:placeholder_user) }
  let(:project) { build_stubbed(:project) }
  let(:instance) { described_class.new(project) }

  context "with a project" do
    before do
      allow(project)
        .to receive(:principals)
        .and_return([user, group, placeholder_user])
    end

    describe "#user_values" do
      it "returns a user array" do
        expect(instance.user_values).to contain_exactly([nil, user.id.to_s])
      end

      it "is empty if no user exists" do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.user_values).to be_empty
      end
    end

    describe "#group_values" do
      it "returns a group array" do
        expect(instance.group_values).to contain_exactly([nil, group.id.to_s])
      end

      it "is empty if no group exists" do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.group_values).to be_empty
      end
    end

    describe "#principal_values" do
      it "returns an array of principals as [name, id]" do
        expect(instance.principal_values)
          .to contain_exactly([nil, group.id.to_s], [nil, user.id.to_s], [nil, placeholder_user.id.to_s])
      end

      it "is empty if no principal exists" do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.principal_values).to be_empty
      end
    end
  end

  context "without a project" do
    let(:project) { nil }
    let(:visible_projects) { [build_stubbed(:project)] }
    let(:matching_principals) { [user, group, placeholder_user] }

    before do
      allow(Principal)
        .to receive(:visible)
        .and_return(matching_principals)

      without_partial_double_verification do
        allow(matching_principals)
          .to receive(:not_builtin)
                .and_return(matching_principals)
      end
    end

    describe "#user_values" do
      it "returns a user array" do
        expect(instance.user_values).to contain_exactly([nil, user.id.to_s])
      end

      context "if no user exists" do
        let(:matching_principals) { [group] }

        it "is empty" do
          expect(instance.user_values).to be_empty
        end
      end
    end

    describe "#group_values" do
      it "returns a group array" do
        expect(instance.group_values).to contain_exactly([nil, group.id.to_s])
      end

      context "if no group exists" do
        let(:matching_principals) { [user] }

        it "is empty" do
          expect(instance.group_values).to be_empty
        end
      end
    end

    describe "#principal_values" do
      it "returns an array of principals as [name, id]" do
        expect(instance.principal_values)
          .to contain_exactly([nil, group.id.to_s], [nil, user.id.to_s], [nil, placeholder_user.id.to_s])
      end

      context "if no principals exist" do
        let(:matching_principals) { [] }

        it "is empty" do
          expect(instance.principal_values).to be_empty
        end
      end
    end
  end
end
