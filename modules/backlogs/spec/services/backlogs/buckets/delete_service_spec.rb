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
require "services/base_services/behaves_like_delete_service"

RSpec.describe Backlogs::Buckets::DeleteService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[backlogs work_package_tracking]) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:no_bucket_wp1) { create(:work_package, project:) }
  shared_let(:bucket_wp1) { create(:work_package, project:, backlog_bucket: bucket) }
  shared_let(:bucket_wp2) { create(:work_package, project:, backlog_bucket: bucket) }

  let(:permissions) { %i[view_sprints create_sprints] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:instance) { described_class.new(user:, model: bucket) }

  subject { instance.call }

  it_behaves_like "BaseServices delete service" do
    let(:model_class) { BacklogBucket }
    let(:factory) { :backlog_bucket }
  end

  context "when the contract is valid" do
    it "moves the work packages to the inbox (no bucket - updating the positions)", :aggregate_failures do
      expect(subject).to be_success

      # 1 is already taken by no_bucket_wp1
      expect(bucket_wp1.reload).to have_attributes(backlog_bucket: nil, position: 2)
      expect(bucket_wp2.reload).to have_attributes(backlog_bucket: nil, position: 3)
    end
  end

  context "when the contract is invalid" do
    let(:permissions) { %i[view_sprints] }

    it "leaves the work packages where they are", :aggregate_failures do
      expect(subject).to be_failure

      expect(bucket_wp1.reload).to have_attributes(backlog_bucket: bucket, position: 1)
      expect(bucket_wp2.reload).to have_attributes(backlog_bucket: bucket, position: 2)
    end
  end
end
