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

RSpec.describe Wikis::Admin::Forms::RedirectUriFormComponent, type: :component do
  let(:wiki_provider) { create(:xwiki_provider, :with_oauth_client) }

  subject { render_inline(described_class.new(wiki_provider)) && page }

  it "renders the redirect uri as a read only field" do
    expect(subject).to have_field(type: "text", with: wiki_provider.oauth_client.redirect_uri, readonly: true)
  end

  it "renders a clipboard copy button for the redirect uri" do
    expect(subject).to have_css("clipboard-copy[value='#{wiki_provider.oauth_client.redirect_uri}']")
  end

  it "submits to the finish setup endpoint" do
    expect(subject).to have_css("form[method='post'][action$='oauth_client/finish_setup']")
    expect(subject).to have_button(I18n.t(:button_finish_setup), disabled: false)
  end

  it "renders the copy instructions" do
    expect(subject).to have_text(I18n.t("wikis.admin.wiki_providers.oauth.redirect_uri_caption"))
  end

  context "when rendered read only" do
    subject { render_inline(described_class.new(wiki_provider, read_only: true)) && page }

    it "renders a close button instead of the submit buttons" do
      expect(subject).to have_css("a[href$='wiki_providers/#{wiki_provider.id}/edit']", text: I18n.t(:button_close))
    end

    it "renders no submit button" do
      expect(subject).to have_no_button(type: "submit")
    end
  end
end
