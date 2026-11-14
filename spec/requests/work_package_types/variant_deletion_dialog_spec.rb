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

RSpec.describe "GET /types/:type_id/variants/:id/deletion_dialog", :aggregate_failures, :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }

  let(:dialog) { Capybara.string(response.body[%r{<template>(.*)</template>}m, 1].to_s) }

  before { login_as(admin) }

  def open_dialog(**)
    get(deletion_dialog_type_variant_path(type_id: bug.id, id: variant.id, **), as: :turbo_stream)

    expect(response).to have_http_status(:ok)
  end

  shared_examples "returning to the page the menu was opened from" do
    it "returns there once deleted" do
      open_dialog(back_url: type_variants_path(type_id: bug.id))

      expect(dialog).to have_css(
        "form[action='#{type_variant_path(type_id: bug.id, id: variant.id,
                                          back_url: type_variants_path(type_id: bug.id))}']"
      )
    end
  end

  context "when no project applies the variant" do
    it "confirms the deletion in a danger dialog" do
      open_dialog

      expect(dialog).to have_test_selector("unused-variant-deletion-dialog")
      expect(dialog).to have_text("Delete variant 'Bug: Hardware'?", normalize_ws: true)
      expect(dialog).to have_text("This action cannot be undone.", normalize_ws: true)
      expect(dialog).to have_css("form[action='#{type_variant_path(type_id: bug.id, id: variant.id)}']")
    end

    it_behaves_like "returning to the page the menu was opened from"
  end

  context "when projects apply the variant" do
    before do
      project = create(:project, types: [bug])
      project.project_types.find_by(type: bug).update!(variant:)
    end

    it "asks for the variant the projects switch to" do
      open_dialog

      expect(dialog).to have_no_test_selector("unused-variant-deletion-dialog")
      expect(dialog).to have_text("The projects using this variant will be switched", normalize_ws: true)
    end

    it_behaves_like "returning to the page the menu was opened from"
  end
end
