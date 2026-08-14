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

# The variant screens carry an optional project prefix, which makes :project_id the first segment
# these routes have. A positional argument therefore fills the project rather than the type as soon
# as the type is already a path parameter — silently, with a plausible URL naming the type's id as a
# project. Every call site was normalised to keyword arguments for that reason; this is what keeps
# them that way, because nothing in Ruby or Rails will complain about a positional one.
#
# Deliberately a controller spec: the trap only exists in a request context, where path parameters
# are there to be fallen back on. Generated from the bare url_helpers it looks correct either way.
module WorkPackageTypes
  RSpec.describe WorkflowTabController do
    shared_let(:type) { create(:type) }
    shared_let(:project) { create(:project) }

    current_user { create(:admin) }

    before { get :edit, params: { type_id: type.id } }

    it "puts the type in the type's segment when it is named" do
      expect(edit_type_workflow_path(type_id: type.id)).to eq("/types/#{type.id}/workflow/edit")
    end

    it "leaves the project out of an administration path" do
      expect(edit_type_workflow_path(type_id: type.id)).not_to include("/projects/")
    end

    it "reaches the project's copy of the same screen when the project is named" do
      expect(edit_type_workflow_path(project_id: project.identifier, type_id: type.id))
        .to eq("/projects/#{project.identifier}/settings/work_packages/types/#{type.id}/workflow/edit")
    end

    # What a positional argument does here, recorded so the surprise is on the record rather than
    # in a URL: it fills the project, not the type.
    it "fills the project from a positional argument, which is why call sites name their arguments" do
      expect(edit_type_workflow_path(type)).to include("/projects/#{type.id}/")
    end
  end
end
