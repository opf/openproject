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

# This file can be safely deleted once the feature flag :percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
RSpec.describe API::V3::WorkPackages::Schema::TypedWorkPackageSchema, "pre 14.4 without percent complete edition",
               with_flag: { percent_complete_edition: false } do
  let(:project) { build(:project) }
  let(:type) { build(:type) }

  let(:current_user) { build_stubbed(:user) }

  subject { described_class.new(project:, type:) }

  before do
    login_as(current_user)
    mock_permissions_for(current_user, &:allow_everything)
  end

  describe "#writable?" do
    it "percentage done is not writable in work-based progress calculation mode",
       with_settings: { work_package_done_ratio: "field" } do
      expect(subject).not_to be_writable(:done_ratio)
    end

    it "percentage done is not writable in status-based progress calculation mode",
       with_settings: { work_package_done_ratio: "status" } do
      expect(subject).not_to be_writable(:done_ratio)
    end
  end
end
