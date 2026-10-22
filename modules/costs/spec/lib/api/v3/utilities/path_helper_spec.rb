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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative Rails.root.join("spec/lib/api/v3/utilities/path_helper_examples").to_s

RSpec.describe API::V3::Utilities::PathHelper do
  include_context "on api v3 paths"

  describe "time_entry paths" do
    it_behaves_like "resource", :time_entry

    describe "#time_entries_activity" do
      subject { helper.time_entries_activity 42 }

      it_behaves_like "api v3 path", "/time_entries/activities/42"
    end

    describe "#time_entries_available_projects" do
      subject { helper.time_entries_available_projects }

      it_behaves_like "api v3 path", "/time_entries/available_projects"
    end
  end
end
