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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe GitlabBranch do
  describe "Associations" do
    it { is_expected.to belong_to(:work_package) }
    it { is_expected.to belong_to(:gitlab_user).optional }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of :gitlab_project_id }
    it { is_expected.to validate_presence_of :namespace }
    it { is_expected.to validate_presence_of :project_html_url }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :repository }
  end

  describe "URLs derived from the project" do
    subject(:branch) do
      build_stubbed(:gitlab_branch,
                    project_html_url: "https://gitlab.com/openproject/openproject",
                    name: "feature/dp-7-invite-attendees")
    end

    it "points at the branch tree" do
      expect(branch.html_url)
        .to eq("https://gitlab.com/openproject/openproject/-/tree/feature/dp-7-invite-attendees")
    end

    it "prefills the source branch of a new merge request" do
      expect(branch.new_merge_request_url)
        .to eq("https://gitlab.com/openproject/openproject/-/merge_requests/new" \
               "?merge_request%5Bsource_branch%5D=feature%2Fdp-7-invite-attendees")
    end
  end
end
