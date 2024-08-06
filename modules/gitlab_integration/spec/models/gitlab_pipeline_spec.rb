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
require_module_spec_helper

RSpec.describe GitlabPipeline do
  describe "Associations" do
    it { is_expected.to belong_to(:gitlab_merge_request).touch(true) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of :gitlab_user_avatar_url }
    it { is_expected.to validate_presence_of :gitlab_html_url }
    it { is_expected.to validate_presence_of :gitlab_id }
    it { is_expected.to validate_presence_of :status }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :ci_details }
    it { is_expected.to validate_presence_of :commit_id }
    it { is_expected.to validate_presence_of :username }
  end

  describe "Enums" do
    let(:gitlab_pipeline) { build(:gitlab_pipeline) }

    it do
      expect(gitlab_pipeline).to define_enum_for(:status)
        .with_values(created: "created",
                     running: "running",
                     success: "success",
                     waiting: "waiting",
                     preparing: "preparing",
                     failed: "failed",
                     pending: "pending",
                     canceled: "canceled",
                     skipped: "skipped",
                     manual: "manual",
                     scheduled: "scheduled")
        .backed_by_column_of_type(:string)
    end
  end
end
