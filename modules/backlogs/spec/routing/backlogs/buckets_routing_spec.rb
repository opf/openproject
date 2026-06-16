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

RSpec.describe Backlogs::BucketsController do
  describe "routing" do
    it {
      route = "/projects/project_42/backlogs/buckets"
      expect(post(route)).to route_to(controller: "backlogs/buckets",
                                      action: "create",
                                      project_id: "project_42")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/23"
      expect(patch(route)).to route_to(controller: "backlogs/buckets",
                                       action: "update",
                                       project_id: "project_42",
                                       id: "23")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/23"
      expect(put(route)).to route_to(controller: "backlogs/buckets",
                                     action: "update",
                                     project_id: "project_42",
                                     id: "23")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/23"
      expect(delete(route)).to route_to(controller: "backlogs/buckets",
                                        action: "destroy",
                                        project_id: "project_42",
                                        id: "23")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/new_dialog"
      expect(get(route)).to route_to(controller: "backlogs/buckets",
                                     action: "new_dialog",
                                     project_id: "project_42")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/23/edit_dialog"
      expect(get(route)).to route_to(controller: "backlogs/buckets",
                                     action: "edit_dialog",
                                     project_id: "project_42",
                                     id: "23")
    }

    it {
      route = "/projects/project_42/backlogs/buckets/23/destroy_dialog"
      expect(get(route)).to route_to(controller: "backlogs/buckets",
                                     action: "destroy_dialog",
                                     project_id: "project_42",
                                     id: "23")
    }
  end

  describe "named routing" do
    it {
      expect(project_backlogs_buckets_path(project_id: "project_42"))
        .to eq("/projects/project_42/backlogs/buckets")
    }

    it {
      expect(project_backlogs_bucket_path(project_id: "project_42", id: "23"))
        .to eq("/projects/project_42/backlogs/buckets/23")
    }

    it {
      expect(new_dialog_project_backlogs_buckets_path(project_id: "project_42"))
        .to eq("/projects/project_42/backlogs/buckets/new_dialog")
    }

    it {
      expect(edit_dialog_project_backlogs_bucket_path(project_id: "project_42", id: "23"))
        .to eq("/projects/project_42/backlogs/buckets/23/edit_dialog")
    }

    it {
      expect(destroy_dialog_project_backlogs_bucket_path(project_id: "project_42", id: "23"))
        .to eq("/projects/project_42/backlogs/buckets/23/destroy_dialog")
    }
  end
end
