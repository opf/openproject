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

RSpec.describe OpenProject::JournalFormatter::WikiDiff do
  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper
    Rails.application.routes.url_helpers
  end

  let(:klass) { described_class }
  let(:project) { build_stubbed(:project) }
  let(:wiki) { build_stubbed(:wiki, project:) }
  let(:wiki_page) do
    build_stubbed(:wiki_page, wiki:, slug: "test-slug", text: "").tap do |page|
      allow(page).to receive(:project).and_return(project)
    end
  end
  let(:wiki_journal) do
    build_stubbed(:wiki_page_journal,
                  journable: wiki_page,
                  version: 1)
  end
  let(:wiki_instance) { klass.new(wiki_journal) }
  let(:wiki_key) { "text" }
  let(:path) do # path
    url_helper.wiki_diff_compare_project_wiki_path(id: wiki_page.slug,
                                                   project_id: project.identifier,
                                                   version: 0,
                                                   version_from: 1)
  end
  let(:url) do # url
    url_helper.wiki_diff_compare_project_wiki_url(id: wiki_page.slug,
                                                  project_id: project.identifier,
                                                  version: 0,
                                                  version_from: 1,
                                                  protocol: Setting.protocol,
                                                  host: Setting.host_name)
  end
  let(:link) { link_to(I18n.t(:label_details), path, class: "diff-details", target: "_top") }
  let(:full_url_link) { link_to(I18n.t(:label_details), url, class: "diff-details") }

  describe "#render" do
    describe "a wiki diff for a wiki journal correctly" do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{wiki_key.camelize}</strong>",
               link:)
      end

      it { expect(wiki_instance.render(wiki_key, ["old value", "new value"])).to be_html_eql(expected) }
    end
  end
end
