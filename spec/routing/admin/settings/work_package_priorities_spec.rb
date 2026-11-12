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

RSpec.describe Admin::Settings::WorkPackagePrioritiesController, "routing" do
  describe "work package priorities" do
    it {
      expect(subject).to route(:get, "admin/settings/work_package_priorities")
        .to(controller: "admin/settings/work_package_priorities", action: "index")
    }

    it {
      expect(subject).to route(:get, "admin/settings/work_package_priorities/new")
        .to(controller: "admin/settings/work_package_priorities", action: "new")
    }

    it {
      expect(subject).to route(:post, "admin/settings/work_package_priorities")
        .to(controller: "admin/settings/work_package_priorities", action: "create")
    }

    it {
      expect(subject).to route(:get, "admin/settings/work_package_priorities/1/edit")
        .to(controller: "admin/settings/work_package_priorities", action: "edit", id: "1")
    }

    it {
      expect(subject).to route(:put, "admin/settings/work_package_priorities/1")
        .to(controller: "admin/settings/work_package_priorities", action: "update", id: "1")
    }

    it {
      expect(subject).to route(:delete, "admin/settings/work_package_priorities/1")
        .to(controller: "admin/settings/work_package_priorities", action: "destroy", id: "1")
    }
  end
end
