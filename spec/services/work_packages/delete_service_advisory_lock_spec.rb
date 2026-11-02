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

RSpec.describe WorkPackages::DeleteService, "closure_tree advisory lock", use_transactional_fixtures: false do
  shared_examples "releases the closure_tree lock before the deletion commits" do |delete_descendants:|
    it "releases the closure_tree lock before the deletion commits" do
      ActiveRecord::Base.transaction do
        parent = nil
        user = nil
        ActiveRecord::Base.transaction(requires_new: true) do
          user = create(:admin)
          parent = create(:work_package)
          create(:work_package, project: parent.project, parent:)
        end

        result = described_class.new(user:, model: parent).call(delete_descendants:)

        expect(result).to be_success
        expect(WorkPackage.advisory_lock_exists?(WorkPackage._ct.advisory_lock_name)).to be(false)

        raise ActiveRecord::Rollback
      end
    end
  end

  context "when deleting the descendants" do
    it_behaves_like "releases the closure_tree lock before the deletion commits", delete_descendants: true
  end

  context "when detaching the descendants" do
    it_behaves_like "releases the closure_tree lock before the deletion commits", delete_descendants: false
  end
end
