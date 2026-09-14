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

RSpec.describe OAuth::Applications::IndexComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(oauth_applications:)) }

  context "with applications" do
    let(:oauth_applications) { [create(:oauth_application, name: "My external app")] }

    it "renders the other-applications list with a header and a row per application", :aggregate_failures do
      expect(rendered_component).to have_css("#op-admin-oauth--other-applications.Box") do |box|
        expect(box).to have_css(".Box-header") do |header|
          expect(header).to have_heading(I18n.t("oauth.header.other_applications"))
        end
        expect(box).to have_css(".Box-row", text: "My external app")
      end
    end

    it "renders no empty-state row once rows exist" do
      expect(rendered_component).to have_no_css("#op-admin-oauth--other-applications .Box-row[data-empty-list-item]")
    end
  end

  context "without applications" do
    let(:oauth_applications) { [] }

    it_behaves_like "rendering Blank Slate", heading: I18n.t("oauth.empty_application_lists")

    it "renders the empty state inside the other-applications list" do
      expect(rendered_component).to have_css("#op-admin-oauth--other-applications .blankslate")
    end
  end
end
