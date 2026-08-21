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

require "rails_helper"

RSpec.describe WorkPackageTypes::ProjectsTab::AddDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type) }

  let(:variant) { type.default_variant }

  before { render_inline(described_class.new(variant:)) }

  it "keeps the form inside the body, with the footer outside it" do
    expect(page).to have_css(".Overlay-body form##{WorkPackageTypes::ProjectsTab::AddFormComponent::FORM_ID}")
    expect(page).to have_no_css(".Overlay-footer form")
  end

  it "submits that form from the footer by id" do
    expect(page).to have_css(
      ".Overlay-footer button[type=submit][form='#{WorkPackageTypes::ProjectsTab::AddFormComponent::FORM_ID}']"
    )
  end

  it "posts to the variant's link action" do
    expect(page).to have_css("form[action='#{link_type_projects_path(**variant.path_args)}']")
  end

  it "names the tree's form field after the field the controller expects" do
    expect(page).to have_css(
      "input[data-target='tree-view.formInputPrototype']" \
      "[name='#{WorkPackageTypes::ProjectsTab::AddFormComponent::FIELD_NAME}[]']",
      visible: :all
    )
  end
end
