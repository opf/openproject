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

RSpec.describe MailFormattingHelper do
  shared_let(:project) { create(:project, identifier: "macroproj") }
  shared_let(:work_package) { create(:work_package, project:, subject: "test task") }
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  describe "#format_mail_html" do
    subject(:rendered) { helper.format_mail_html("see ###{work_package.id}") }

    it "renders the quickinfo macro as a static anchor (not the Angular custom element)" do
      expect(rendered).to include(%(class="issue work_package))
      expect(rendered).not_to include("<opce-macro-wp-quickinfo")
    end

    it "uses an absolute URL (no relative path)" do
      expect(rendered).to match(%r{href="https?://[^/"]+/work_packages/})
    end
  end

  describe "#format_mail_text" do
    subject(:rendered) { helper.format_mail_text("see ##{work_package.id}").strip }

    context "in classic identifier mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "strips to plain text with the hash-prefixed numeric id" do
        expect(rendered).to eq("see ##{work_package.id}")
        expect(rendered).not_to include("<")
      end
    end

    context "in semantic identifier mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.allocate_and_register_semantic_id }

      it "strips to plain text with the bare formatted identifier" do
        wp = work_package.reload
        expect(rendered).to eq("see #{wp.formatted_id}")
        expect(rendered).not_to include("<")
      end
    end
  end
end
