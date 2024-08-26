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

RSpec.describe Members::CleanupService, "integration", type: :model do
  subject(:service_call) { instance.call }

  let(:user) { create(:user) }
  let(:users) { [user] }
  let(:project) { create(:project) }
  let(:projects) { [project] }
  let(:instance) do
    described_class.new(users, projects)
  end

  describe "category unassignment" do
    let!(:category) do
      build(:category, project:, assigned_to: user).tap do |c|
        c.save(validate: false)
      end
    end

    it "sets assigned_to to nil" do
      service_call

      expect(category.reload.assigned_to)
        .to be_nil
    end

    context "with the user having a membership with an assignable role" do
      before do
        create(:member,
               principal: user,
               project:,
               roles: [create(:project_role, permissions: %i[work_package_assigned])])
      end

      it "keeps assigned_to to the user" do
        service_call

        expect(category.reload.assigned_to)
          .to eql user
      end
    end

    context "with the user having a membership with an unassignable role" do
      before do
        create(:member,
               principal: user,
               project:,
               # Lacking work_package_assigned
               roles: [create(:project_role, permissions: [])])
      end

      it "sets assigned_to to nil" do
        service_call

        expect(category.reload.assigned_to)
          .to be_nil
      end
    end
  end

  describe "watcher pruning" do
    let(:work_package) do
      create(:work_package,
             project:)
    end
    let!(:watcher) do
      build(:watcher,
            watchable: work_package,
            user:) do |w|
        w.save(validate: false)
      end
    end

    it "removes the watcher" do
      service_call

      expect { watcher.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    context "with the user having a membership granting the right to view the watchable" do
      before do
        create(:member,
               principal: user,
               project:,
               roles: [create(:project_role, permissions: [:view_work_packages])])
      end

      it "keeps the watcher" do
        service_call

        expect { watcher.reload }
          .not_to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with the user having a membership not granting the right to view the watchable" do
      before do
        create(:member,
               principal: user,
               project:,
               roles: [create(:project_role, permissions: [])])
      end

      it "keeps the watcher" do
        service_call

        expect { watcher.reload }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
