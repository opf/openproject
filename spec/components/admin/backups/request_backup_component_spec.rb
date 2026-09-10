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

RSpec.describe Admin::Backups::RequestBackupComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) { render_inline(described_class.new(**args)) }

  let(:args) do
    {
      last_backup_attachment_id: last_backup_attachment_id,
      last_backup_date: "2026-09-01",
      may_include_attachments: may_include_attachments
    }
  end
  let(:last_backup_attachment_id) { nil }
  let(:may_include_attachments) { true }

  context "without a previous backup" do
    it "does not render the last backup section" do
      expect(rendered_component).to have_no_text(I18n.t("js.backup.last_backup"))
      expect(rendered_component).to have_no_link(I18n.t("js.backup.download_backup"))
    end
  end

  context "with a previous backup" do
    let(:last_backup_attachment_id) { 42 }

    it "renders the last backup date and a download link to the attachment" do
      expect(rendered_component).to have_css("h3", text: I18n.t("js.backup.last_backup"))
      expect(rendered_component).to have_text(I18n.t("js.backup.last_backup_from"))
      expect(rendered_component).to have_css("em", text: "2026-09-01")
      expect(rendered_component).to have_link(
        I18n.t("js.backup.download_backup"),
        href: API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(42)
      )
    end
  end

  it "renders the backup title, info text and warning note" do
    expect(rendered_component).to have_css("h3", text: I18n.t("js.backup.title"))
    expect(rendered_component).to have_text(I18n.t("js.backup.info"))
    expect(rendered_component).to have_text(I18n.t("js.backup.note"))
  end

  it "renders a form requesting a backup with a backup token field" do
    expect(rendered_component).to have_css(
      "form[action='#{request_backup_admin_backups_path}'][method='post']"
    )
    expect(rendered_component).to have_css("input[type='password'][name='backup_token'][aria-required='true']")
    expect(rendered_component).to have_button(I18n.t("js.backup.request_backup"))
  end

  context "when attachments may be included" do
    let(:may_include_attachments) { true }

    it "renders a checked include_attachments checkbox and no warning" do
      expect(rendered_component).to have_css("input[type='checkbox'][name='include_attachments'][checked]")
      expect(rendered_component).to have_no_text(I18n.t("js.backup.attachments_disabled"))
    end
  end

  context "when attachments may not be included" do
    let(:may_include_attachments) { false }

    it "does not render the include_attachments checkbox but shows a warning" do
      expect(rendered_component).to have_no_field("include_attachments")
      expect(rendered_component).to have_text(I18n.t("js.backup.attachments_disabled"))
    end
  end
end
