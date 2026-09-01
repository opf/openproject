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

RSpec.describe "The variant switch dialog",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:delivery) { create(:type_variant, type: epic, variant_name: "Delivery") }
  shared_let(:project) { create(:project, types: [epic]) }
  shared_let(:ours) { create(:project_owned_type_variant, type: epic, project:, variant_name: "Internal") }
  shared_let(:theirs) do
    create(:project_owned_type_variant, type: epic, project: create(:project), variant_name: "Demo only")
  end

  before { login_as admin }

  def open_dialog(**params)
    get new_project_settings_work_packages_type_switch_path(project, epic, **params), as: :turbo_stream
  end

  # The dialog arrives inside a turbo-stream template, whose contents Capybara does not enter.
  def dialog = Capybara.string(Nokogiri::HTML5.fragment(response.body).css("template").inner_html)

  # A row's action names the variant it was asked from, so the reader does not have to find it
  # again in the select.
  it "opens on the variant it was asked about" do
    open_dialog(target_id: delivery.id)

    expect(response).to have_http_status(:ok)
    expect(dialog).to have_select("Variant", selected: delivery.composite_name)
  end

  # The reader chose on the row they came from, so the dialog states the choice rather than asking
  # for it again; the select is there to change one's mind, not to make the decision.
  it "does not ask the reader to choose a variant" do
    open_dialog(target_id: delivery.id)

    expect(dialog).to have_no_text("Select a different variant of this type to use in this project.")
  end

  it "opens on the project's own variant when that is the one asked about" do
    open_dialog(target_id: ours.id)

    expect(dialog).to have_select("Variant", selected: ours.composite_name)
  end

  it "opens on the variant in use when asked about none" do
    open_dialog

    expect(dialog).to have_select("Variant", selected: epic.default_variant.composite_name)
  end

  # The parameter comes off a URL, so it decides nothing on its own: a variant this project may
  # not use is no more selectable here than it is in the list.
  it "ignores a variant another project owns" do
    open_dialog(target_id: theirs.id)

    expect(dialog).to have_select("Variant", selected: epic.default_variant.composite_name)
  end
end
