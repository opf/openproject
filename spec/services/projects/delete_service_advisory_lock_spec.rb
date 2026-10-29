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

RSpec.describe Projects::DeleteService, "closure_tree advisory lock", use_transactional_fixtures: false do
  it "releases the closure_tree lock before the deletion commits" do
    ActiveRecord::Base.transaction do
      project = nil
      user = nil
      ActiveRecord::Base.transaction(requires_new: true) do
        user = create(:admin)
        project = create(:project)
        parent = create(:work_package, project:)
        create(:work_package, project:, parent:)
      end

      result = described_class.new(user:, model: project).call

      expect(result).to be_success
      expect(WorkPackage.where(project_id: project.id)).to be_empty
      expect(WorkPackage.advisory_lock_exists?(WorkPackage._ct.advisory_lock_name)).to be(false)

      raise ActiveRecord::Rollback
    end
  end
end
