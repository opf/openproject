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

RSpec.describe Wikis::Admin::RedirectUriInfoComponent, type: :component do
  let(:wiki_provider) { create(:xwiki_provider) }
  let(:oauth_client) { build(:oauth_client, integration: wiki_provider, client_id: "openproject-1234") }

  subject { render_inline(described_class.new(wiki_provider)) && page }

  context "without an oauth client" do
    before { allow(wiki_provider).to receive(:oauth_client).and_return(nil) }

    it "renders the incomplete label" do
      expect(subject).to have_text(I18n.t(:label_incomplete))
    end

    it "renders the description instead of a redirect uri" do
      expect(subject).to have_text(I18n.t("wikis.admin.redirect_uri_info_component.description"))
    end

    it "does not render the show redirect uri button" do
      expect(subject).to have_no_css("a[href$='oauth_client/show_redirect_uri']")
    end
  end

  context "with an oauth client configured" do
    before { allow(wiki_provider).to receive(:oauth_client).and_return(oauth_client) }

    it "renders the completed label" do
      expect(subject).to have_text(I18n.t(:label_completed))
    end

    it "renders the redirect uri" do
      expect(subject).to have_text(oauth_client.redirect_uri)
    end

    it "renders the show redirect uri button" do
      expect(subject).to have_css("a[href$='oauth_client/show_redirect_uri'][data-turbo-stream='true']")
    end

    it "labels the show redirect uri button" do
      expect(subject).to have_css("tool-tip",
                                  text: I18n.t("wikis.admin.redirect_uri_info_component.show_redirect_uri"),
                                  visible: :all)
    end
  end
end
