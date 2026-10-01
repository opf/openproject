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

RSpec.describe Admin::Labels::DialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) do
    with_request_url "/admin/labels" do
      render_inline(described_class.new(label:))
    end
  end

  context "for a new label" do
    let(:label) { Label.new }

    it "renders the create title" do
      rendered_component

      expect(page).to have_css("h1", text: "Create label")
    end

    it "submits via a Create button bound to the form" do
      rendered_component

      expect(page).to have_css("button[form='admin-label-form'][type='submit']", text: "Create")
    end

    it "renders a Cancel button that closes the dialog" do
      rendered_component

      expect(page).to have_css("button[data-close-dialog-id='admin-label-dialog']", text: "Cancel")
    end
  end

  context "for a persisted label" do
    let(:label) { create(:label, name: "Machine Learning") }

    it "renders the rename title with the label's name" do
      rendered_component

      expect(page).to have_css("h1", text: 'Rename "Machine Learning"')
    end

    it "submits via a Rename button bound to the form" do
      rendered_component

      expect(page).to have_css("button[form='admin-label-form'][type='submit']", text: "Rename")
    end
  end
end
