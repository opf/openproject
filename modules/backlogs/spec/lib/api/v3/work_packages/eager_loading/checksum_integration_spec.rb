# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative Rails.root.join("spec/lib/api/v3/work_packages/eager_loading/eager_loading_mock_wrapper")

RSpec.describe API::V3::WorkPackages::EagerLoading::Checksum, "integration" do
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:other_sprint) { create(:sprint, project:) }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           sprint:)
  end

  describe ".apply" do
    def checksum
      EagerLoadingMockWrapper.wrap(described_class, [work_package]).first.cache_checksum
    end

    it "produces a different checksum on changes to the sprint id" do
      expect { WorkPackage.where(id: work_package.id).update_all(sprint_id: other_sprint.id) }
        .to change { checksum }
    end

    it "produces a different checksum on changes to the sprint" do
      expect { sprint.update_attribute(:updated_at, 10.seconds.from_now) }
        .to change { checksum }
    end
  end
end
