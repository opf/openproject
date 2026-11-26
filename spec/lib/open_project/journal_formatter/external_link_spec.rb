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

RSpec.describe OpenProject::JournalFormatter::ExternalLink, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  let(:external_link) do
    create(:external_link, work_package:, title: "Release plan", url: "https://example.com/plan")
  end
  let(:journal) { work_package.last_journal }

  current_user { user }

  before do
    change_external_links { external_link }
  end

  def change_external_links
    yield
    work_package.save_journals
  end

  def render(attribute, html: true)
    journal.render_detail("external_links_#{external_link.id}_#{attribute}", html:)
  end

  context "when a link is added" do
    it "renders one line naming the link" do
      expect(render(:url)).to eq("External link <i>Release plan</i> added")
      expect(render(:url, html: false)).to eq("External link Release plan added")
    end

    context "when the link has no title" do
      let(:external_link) { create(:external_link, work_package:, title: nil, url: "https://example.com/plan") }

      it "names the link by its URL" do
        expect(render(:url)).to eq("External link <i>https://example.com/plan</i> added")
      end
    end

    context "when the title contains HTML" do
      let(:external_link) { create(:external_link, work_package:, title: "<b>Plan</b>") }

      it "escapes the title" do
        expect(render(:url)).to eq("External link <i>&lt;b&gt;Plan&lt;/b&gt;</i> added")
      end
    end
  end

  context "when a link is removed" do
    before do
      change_external_links { external_link.destroy! }
    end

    it "renders one line naming the link" do
      expect(render(:url)).to eq("External link <i>Release plan</i> removed")
    end
  end

  context "when the title of a link changes" do
    before do
      change_external_links { external_link.update!(title: "Roadmap") }
    end

    it "renders the change, naming the link by its new title" do
      expect(render(:title))
        .to eq("<strong>Title of external link Roadmap</strong> changed from <i>Release plan</i> to <i>Roadmap</i>")
      expect(render(:title, html: false))
        .to eq("Title of external link Roadmap changed from Release plan to Roadmap")
    end
  end

  context "when the description of a link is set" do
    before do
      change_external_links { external_link.update!(description: "Plan for the next release") }
    end

    it "renders a link to the diff instead of the description" do
      expect(render(:description)).to eq(
        "<strong>Description of external link Release plan</strong> set " \
        "(<a target=\"_top\" class=\"diff-details\" " \
        "href=\"/journals/#{journal.id}/diff/external_links_#{external_link.id}_description\">Details</a>)"
      )
    end
  end
end
