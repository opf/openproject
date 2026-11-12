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

require "rails_helper"

RSpec.describe Admin::CustomFields::Forms::ListComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_list(forms, filtered: false)
    with_request_url "/admin/settings/work_package_custom_fields/1/forms" do
      render_inline(described_class.new(forms:, filtered:))
    end
  end

  context "with a form that has a description" do
    shared_let(:form) { create(:form_configuration, name: "Hardware form", description: "For hardware") }

    it "links the form name to its edit page and renders its description" do
      rendered = render_list(FormConfiguration.where(id: form.id).page(1).per_page(20))

      expect(rendered).to have_link("Hardware form", href: edit_form_configuration_path(form))
      expect(rendered).to have_text("For hardware")
    end
  end

  context "with no forms and no active filter" do
    it "renders the empty blank slate" do
      rendered = render_list([])

      expect(rendered).to have_text(I18n.t("custom_fields.show.forms.blank_slate.title"))
    end
  end

  context "with no forms but an active filter" do
    it "renders the no-matches blank slate" do
      rendered = render_list([], filtered: true)

      expect(rendered).to have_text(I18n.t("custom_fields.show.forms.blank_slate.filtered_title"))
    end
  end
end
