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

# Test for a project picker that is backed by the project autocompleter:
# searching a project's identifier has to surface the matching project.
#
# The including example group has to provide:
#
# * `target_project`  - the project that is searched for by its identifier
# * `control_project` - another project the picker offers, which must disappear
#                       once the target's identifier is searched
# * `search_project(query)` - runs the picker's search for `query` and returns
#                             the open dropdown as a Capybara element
RSpec.shared_examples "a project picker searchable by identifier" do
  before do
    target_project
    control_project
  end

  it "finds a project by its identifier, which is never displayed itself" do
    dropdown = search_project("")
    expect(dropdown).to have_text(target_project.name)
    expect(dropdown).to have_text(control_project.name)

    dropdown = search_project(target_project.identifier)

    expect(dropdown).to have_no_text(control_project.name)
    expect(dropdown).to have_text(target_project.name)
  end
end
