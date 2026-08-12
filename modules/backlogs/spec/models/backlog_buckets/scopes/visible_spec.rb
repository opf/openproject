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

RSpec.describe BacklogBuckets::Scopes::Visible do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:other_bucket) { create(:backlog_bucket, project: other_project) }

  shared_let(:user_with_permission) do
    create(:user, member_with_permissions: { project => %i[view_sprints] })
  end
  shared_let(:user_without_permission) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:user_without_membership) { create(:user) }

  subject { BacklogBucket.visible(current_user) }

  context "for a user with view_sprints in the project" do
    current_user { user_with_permission }

    it "returns only the buckets in projects the user has permission for" do
      expect(subject).to contain_exactly(bucket)
    end
  end

  context "for a user without view_sprints permission" do
    current_user { user_without_permission }

    it "returns no buckets" do
      expect(subject).to be_empty
    end
  end

  context "for a user without any project membership" do
    current_user { user_without_membership }

    it "returns no buckets" do
      expect(subject).to be_empty
    end
  end

  context "when called without a user argument" do
    current_user { user_with_permission }

    it "uses User.current" do
      expect(BacklogBucket.visible).to contain_exactly(bucket)
    end
  end
end
