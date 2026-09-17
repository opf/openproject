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

RSpec.describe Admin::Labels::DeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) do
    with_request_url "/admin/labels" do
      render_inline(described_class.new(label))
    end
  end

  let(:label) { create(:label, name: "Machine Learning") }

  it "renders the confirmation heading and the description with the label name in bold" do
    rendered_component

    expect(page).to have_css("h2", text: "Delete this label?")
    expect(page).to have_text("This will remove the label Machine Learning from all work packages in all projects.")
    expect(page).to have_css("strong", text: "Machine Learning")
  end

  it "renders the required confirmation checkbox" do
    rendered_component

    expect(page).to have_field("I understand that this action is not reversible", type: "checkbox")
  end

  it "submits a DELETE to the label's own path" do
    rendered_component

    expect(page).to have_css("form[action='#{admin_label_path(label)}']")
    expect(page).to have_css("input[name='_method'][value='delete']", visible: :all)
  end

  it "labels the confirm button Delete rather than Delete permanently" do
    rendered_component

    expect(page).to have_button("Delete")
    expect(page).to have_no_button("Delete permanently")
  end

  it "labels the cancel button Close" do
    rendered_component

    expect(page).to have_button("Close")
    expect(page).to have_no_button("Cancel")
  end
end
