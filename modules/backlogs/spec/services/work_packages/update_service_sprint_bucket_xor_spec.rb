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

RSpec.describe WorkPackages::UpdateService, "sprint and bucket mutual exclusivity", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[backlogs work_package_tracking]) }

  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:other_sprint) { create(:sprint, project:) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:other_bucket) { create(:backlog_bucket, project:) }

  let(:permissions) do
    %i[
      view_work_packages
      edit_work_packages
      view_sprints
      manage_sprint_items
    ]
  end

  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let(:instance) { described_class.new(user:, model: work_package) }

  current_user { user }

  context "when the work package has a sprint assigned" do
    let(:work_package) { create(:work_package, project:, sprint:) }

    it "clears the sprint when a bucket is assigned" do
      result = instance.call(backlog_bucket: bucket)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
    end

    it "keeps sprint unchanged when no bucket is passed" do
      result = instance.call(sprint:)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint:, backlog_bucket: nil)
    end

    it "allows explicitly clearing sprint while setting bucket in the same call" do
      result = instance.call(sprint: nil, backlog_bucket: bucket)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
    end
  end

  context "when the work package has a bucket assigned" do
    let(:work_package) { create(:work_package, project:, backlog_bucket: bucket) }

    it "clears the bucket when a sprint is assigned" do
      result = instance.call(sprint:)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint:, backlog_bucket: nil)
    end

    it "keeps backlog bucket unchanged when no sprint is passed" do
      result = instance.call(backlog_bucket: bucket)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
    end

    it "allows explicitly clearing bucket while setting sprint in the same call" do
      result = instance.call(sprint:, backlog_bucket: nil)

      expect(result).to be_success
      expect(work_package.reload).to have_attributes(sprint:, backlog_bucket: nil)
    end
  end

  context "when sprint and bucket are both set in the same call" do
    let(:work_package) { create(:work_package, project:) }

    it "returns a validation error rather than silently clearing one" do
      result = instance.call(sprint:, backlog_bucket: bucket)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:backlog_bucket_xor_sprint)
      expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: nil)
    end
  end

  context "when sprint is set and bucket is changed in the same call" do
    let(:work_package) { create(:work_package, project:, backlog_bucket: bucket) }

    it "returns a validation error" do
      result = instance.call(sprint:, backlog_bucket: other_bucket)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:backlog_bucket_xor_sprint)
      expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
    end
  end

  context "when sprint is changed and bucket is set in the same call" do
    let(:work_package) { create(:work_package, project:, sprint:) }

    it "returns a validation error" do
      result = instance.call(sprint: other_sprint, backlog_bucket: bucket)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:backlog_bucket_xor_sprint)
      expect(work_package.reload).to have_attributes(sprint:, backlog_bucket: nil)
    end
  end

  context "when only sprint changes (no bucket involved)" do
    context "when the work package has no sprint" do
      let(:work_package) { create(:work_package, project:) }

      it "sets the sprint" do
        result = instance.call(sprint:)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint:, backlog_bucket: nil)
      end
    end

    context "when the work package already has a sprint" do
      let(:work_package) { create(:work_package, project:, sprint:) }

      it "changes the sprint" do
        result = instance.call(sprint: other_sprint)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint: other_sprint, backlog_bucket: nil)
      end

      it "clears the sprint" do
        result = instance.call(sprint: nil)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: nil)
      end
    end
  end

  context "when only bucket changes (no sprint involved)" do
    context "when the work package has no bucket" do
      let(:work_package) { create(:work_package, project:) }

      it "sets the bucket" do
        result = instance.call(backlog_bucket: bucket)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
      end
    end

    context "when the work package already has a bucket" do
      let(:work_package) { create(:work_package, project:, backlog_bucket: bucket) }

      it "changes the bucket" do
        result = instance.call(backlog_bucket: other_bucket)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: other_bucket)
      end

      it "clears the bucket" do
        result = instance.call(backlog_bucket: nil)

        expect(result).to be_success
        expect(work_package.reload).to have_attributes(sprint: nil, backlog_bucket: nil)
      end
    end
  end
end
