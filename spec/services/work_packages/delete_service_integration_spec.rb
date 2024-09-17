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

RSpec.describe WorkPackages::DeleteService, "integration", type: :model do
  shared_let(:project) { create(:project) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[delete_work_packages view_work_packages add_work_packages manage_subtasks])
  end
  shared_let(:user) do
    create(:user, member_with_roles: { project => role })
  end

  describe "deleting a child with estimated_hours set" do
    let(:parent) { create(:work_package, project:, subject: "parent") }
    let(:child) do
      create(:work_package,
             project:,
             parent:,
             subject: "child",
             estimated_hours: 123)
    end

    let(:instance) do
      described_class.new(user:,
                          model: child)
    end

    subject { instance.call }

    before do
      # Ensure estimated_hours is inherited
      WorkPackages::UpdateAncestorsService.new(user:, work_package: child).call(%i[estimated_hours])
      parent.reload
    end

    it "updates the parent estimated_hours" do
      expect(child.estimated_hours).to eq 123
      expect(parent.derived_estimated_hours).to eq 123
      expect(parent.estimated_hours).to be_nil

      expect(subject).to be_success, "Expected service call to be successful, but failed\n" \
                                     "service call errors: #{subject.errors.full_messages.inspect}"

      parent.reload

      expect(parent.estimated_hours).to be_nil
    end
  end

  describe "with a stale work package reference" do
    let!(:work_package) { create(:work_package, project:) }

    let(:instance) do
      described_class.new(user:,
                          model: work_package)
    end

    subject { instance.call }

    it "still destroys it" do
      # Cause lock version changes
      WorkPackage.where(id: work_package.id).update_all(lock_version: work_package.lock_version + 1)

      expect(subject).to be_success
      expect { work_package.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "with a notification" do
    let!(:work_package) { create(:work_package, project:) }
    let!(:notification) do
      create(:notification,
             recipient: user,
             actor: user,
             resource: work_package)
    end

    let(:instance) do
      described_class.new(user:,
                          model: work_package)
    end

    subject { instance.call }

    it "deletes the notification" do
      expect(subject).to be_success
      expect { work_package.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { notification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
