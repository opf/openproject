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
require_relative "eager_loading_mock_wrapper"

RSpec.describe API::V3::WorkPackages::EagerLoading::Hierarchy do
  let!(:parent_work_package) { create(:work_package) }
  let!(:child_work_package) { create(:work_package, parent: parent_work_package) }

  describe ".apply" do
    subject(:wrapped_children) do
      wrapped = EagerLoadingMockWrapper.wrap(described_class, [parent_work_package])
      wrapped.first.children
    end

    it "preloads the children association" do
      wrapped = EagerLoadingMockWrapper.wrap(described_class, [parent_work_package])

      expect(wrapped.first.association(:children)).to be_loaded
      expect(wrapped_children.map(&:id)).to eq([child_work_package.id])
    end

    # Regression: children are loaded with a partial SELECT for performance,
    # so the set of columns must cover everything the representer reads from
    # each child — including `identifier`, which `display_id` consults to
    # render the `_links.children[].displayId` payload in semantic mode.
    it "includes identifier in the partial SELECT so display_id is available" do
      child = wrapped_children.first

      expect(child).to have_attribute(:identifier)
      expect { child.display_id }.not_to raise_error
    end
  end
end
