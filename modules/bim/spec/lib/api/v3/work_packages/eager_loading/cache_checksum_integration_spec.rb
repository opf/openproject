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
#++require 'rspec'

require "spec_helper"
require Rails.root + "spec/lib/api/v3/work_packages/eager_loading/eager_loading_mock_wrapper"

RSpec.describe API::V3::WorkPackages::EagerLoading::Checksum do
  let!(:bcf_issue) do
    create(:bcf_issue,
           work_package:)
  end
  let!(:work_package) do
    create(:work_package)
  end

  describe ".apply" do
    let!(:orig_checksum) do
      EagerLoadingMockWrapper
        .wrap(described_class, [work_package])
        .first
        .cache_checksum
    end

    let(:new_checksum) do
      EagerLoadingMockWrapper
        .wrap(described_class, [work_package])
        .first
        .cache_checksum
    end

    it "produces a different checksum on changes to the bcf issue id" do
      bcf_issue.delete
      create(:bcf_issue,
             work_package:)

      expect(new_checksum)
        .not_to eql orig_checksum
    end

    it "produces a different checksum on changes to the bcf issue" do
      bcf_issue.update_column(:updated_at, Time.now + 10.seconds)

      expect(new_checksum)
        .not_to eql orig_checksum
    end
  end
end
