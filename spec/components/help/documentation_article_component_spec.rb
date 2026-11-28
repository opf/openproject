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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Help::DocumentationArticleComponent, type: :component do
  it "renders the existing documentation with an index and locally served figures", :aggregate_failures do
    render_inline(described_class.new(article_id: "project-life-cycle"))

    expect(page).to have_heading(Help::DocumentationArticle.new("project-life-cycle").title, level: 1)
    expect(page).to have_css("details.contextual-help-contents")
    expect(page).to have_css('img[src*="/help/documentation/project-life-cycle/assets/"]')
    expect(page).to have_no_text("sidebar_navigation:")
  end

  it "keeps related documentation links in the reader" do
    render_inline(described_class.new(article_id: "pmflex-mapping"))

    expect(page).to have_css('a[data-help-article][href*="/help/documentation/project-life-cycle"]')
  end

  it "offers the methodology and subsequent activities for initiation requests" do
    render_inline(described_class.new(article_id: "index", context: "initiation"))

    expect(page).to have_link(I18n.t("contextual_help.articles.initiating-phase"))
    expect(page).to have_link(I18n.t("contextual_help.articles.initiation-settings"))
  end
end
