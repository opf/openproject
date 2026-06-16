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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::Admin::OAuthApplicationInfoComponent, type: :component do
  let(:wiki_provider) { create(:xwiki_provider) }
  let(:oauth_application) { build(:oauth_application, integration: wiki_provider) }

  context "without an oauth application" do
    before { allow(wiki_provider).to receive(:oauth_application).and_return(nil) }

    it "renders the incomplete label" do
      render_inline(described_class.new(wiki_provider))
      expect(page).to have_text(I18n.t(:label_incomplete))
    end

    it "renders the description" do
      render_inline(described_class.new(wiki_provider))
      expect(page).to have_text(I18n.t("wikis.admin.wiki_providers.xwiki.oauth.openproject_oauth_description"))
    end

    it "renders a sync button with a confirm dialog" do
      render_inline(described_class.new(wiki_provider))
      button = page.find("button[type='submit']")
      expect(button["data-turbo-confirm"]).to eq(
        I18n.t("wikis.admin.oauth_application_info_component.confirm_replace_oauth_application")
      )
    end
  end

  context "with an oauth application configured" do
    before { allow(wiki_provider).to receive(:oauth_application).and_return(oauth_application) }

    it "renders the completed label" do
      render_inline(described_class.new(wiki_provider))
      expect(page).to have_text(I18n.t(:label_completed))
    end

    it "renders the oauth application id" do
      render_inline(described_class.new(wiki_provider))
      expect(page).to have_text(
        "#{I18n.t('wikis.admin.oauth_application_info_component.label_oauth_client_id')}: #{oauth_application.uid}"
      )
    end

    it "renders a sync button with a confirm dialog" do
      render_inline(described_class.new(wiki_provider))
      button = page.find("button[type='submit']")
      expect(button["data-turbo-confirm"]).to eq(
        I18n.t("wikis.admin.oauth_application_info_component.confirm_replace_oauth_application")
      )
    end
  end
end
