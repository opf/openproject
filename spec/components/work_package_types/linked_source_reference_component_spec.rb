# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

require "rails_helper"

RSpec.describe WorkPackageTypes::LinkedSourceReferenceComponent, type: :component do
  let(:source) { build_stubbed(:type, name: "Phase") }
  let(:link_path) { "/types/1/subject_configuration/edit" }

  it "names the source and links to it for an admin", :aggregate_failures do
    login_as(build_stubbed(:admin))
    render_inline(described_class.new(source:, link_path:))

    expect(page).to have_text("Configuration reused from Phase")
    expect(page).to have_link("Edit at source", href: link_path)
  end

  it "omits the link when the user is not an admin" do
    login_as(build_stubbed(:user))
    render_inline(described_class.new(source:, link_path:))

    expect(page).to have_no_link("Edit at source")
  end

  it "omits the link when no path is given" do
    login_as(build_stubbed(:admin))
    render_inline(described_class.new(source:))

    expect(page).to have_no_link("Edit at source")
  end
end
