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

RSpec.describe "Types index in global administration",
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:apollo) { create(:project, name: "Apollo") }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:global_variant) { create(:type, name: "Regression", parent: root) }
  shared_let(:owned_variant) { create(:type, name: "Internal", parent: root, project: apollo) }

  before { login_as create(:admin) }

  # An administrator sees every project's variants at once, so an unattributed row
  # would be indistinguishable from a global one.
  it "attributes an owned variant to the project owning it" do
    get types_path(expand: root.id)

    expect(response.body).to include("Owned by Apollo")
  end

  it "shows the owned variant alongside the global one" do
    get types_path(expand: root.id)

    expect(response.body).to include("Internal")
    expect(response.body).to include("Regression")
  end

  # Ownership is the only thing distinguishing the two, so the global one must not
  # pick up the label.
  it "attributes nothing to a global variant" do
    get types_path(expand: root.id)

    expect(response.body.scan("Owned by Apollo").size).to eq(1)
  end
end
