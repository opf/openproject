# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe WorkPackageTypes::PdfExportTemplateController do
  let(:user) { create(:admin) }
  let(:wp_type) { create(:type) }

  current_user { user }

  context "when the user is not logged in" do
    let(:user) { User.anonymous }

    it "responds with forbidden" do
      put :enable_all, params: { type_id: wp_type.id }, as: :turbo_stream
      expect(response).to have_http_status :unauthorized
    end
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    it "responds with forbidden" do
      put :enable_all, params: { type_id: wp_type.id }, as: :turbo_stream
      expect(response).to have_http_status :forbidden
    end
  end

  context "when an admin" do
    def put_reload(endpoint, params = {})
      put endpoint, params: { type_id: wp_type.id }.merge(params), as: :turbo_stream
      wp_type.reload
    end

    def post_reload(endpoint, params = {})
      post endpoint, params: { type_id: wp_type.id }.merge(params), as: :turbo_stream
      wp_type.reload
    end

    context "with no enabled templates" do
      before do
        wp_type.pdf_export_templates.disable_all
        wp_type.save!
      end

      it "enables all templates" do
        put_reload :enable_all
        expect(wp_type.export_templates_disabled.length).to eq(0)
      end

      it "reorder a template" do
        first = wp_type.pdf_export_templates.list.first
        put_reload :drop, { id: first.id, position: 2 } # drop index starts at 1
        wp_type.pdf_export_templates.list[1].id == first.id
      end

      it "toggles enabled/disabled for a template" do
        first = wp_type.pdf_export_templates.list.first
        post_reload :toggle, { id: first.id }
        expect(wp_type.pdf_export_templates.find(first.id).enabled).to be(true)
      end
    end

    context "with all enabled templates" do
      before do
        wp_type.pdf_export_templates.enable_all
        wp_type.save!
      end

      it "disables all templates" do
        put_reload :disable_all
        expect(wp_type.export_templates_disabled.length).to eq(wp_type.pdf_export_templates.list.length)
      end
    end
  end
end
