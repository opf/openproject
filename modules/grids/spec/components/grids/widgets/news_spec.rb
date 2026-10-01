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

RSpec.describe Grids::Widgets::News, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  shared_let(:project_red) { create(:project, name: "Red", enabled_module_names: [:news]) }
  shared_let(:project_blue) { create(:project, name: "Blue", enabled_module_names: [:news]) }
  shared_let(:author) { create(:user) }
  shared_let(:admin) { create(:admin) }

  let(:project) { nil }

  let(:user) { admin }

  current_user { user }

  subject(:rendered_component) { render_component(project) }

  shared_examples "empty-state without action" do
    it "renders empty blankslate without action" do
      expect(rendered_component).to have_test_selector("news-widget-empty")
      expect(rendered_component).to have_text("This widget is currently empty.")
      expect(rendered_component).to have_no_test_selector("news-widget-add-button")
    end
  end

  shared_examples "empty-state with action" do
    it "renders empty blankslate with add action" do
      expect(rendered_component).to have_test_selector("news-widget-empty")
      expect(rendered_component).to have_text("This widget is currently empty.")
      expect(rendered_component).to have_test_selector("news-widget-add-button")
    end
  end

  it "renders turbo-frame wrapper" do
    expect(rendered_component).to have_element :"turbo-frame"
  end

  context "for root" do
    context "with no news" do
      it_behaves_like "empty-state without action"
    end

    context "with news" do
      let!(:news_red) { create(:news, project: project_red, author:) }
      let!(:news_blue) { create(:news, project: project_blue, author:) }

      it "renders news items from all projects", :aggregate_failures do
        expect(rendered_component).to have_list_item(count: 2)
        expect(rendered_component).to have_list_item(position: 2) do |item|
          expect(item).to have_link href: project_news_path(project_red, news_red)
          expect(item).to have_content(/Added by .+ on \d{2}\/\d{2}\/\d{4} \d{2}:\d{2} [AP]M/)
          expect(item).to have_link href: user_path(author)
        end
      end
    end
  end

  context "with project" do
    let(:project) { project_red }
    # these news from another project should not be visible
    let!(:other_project_news) { create(:news, project: project_blue, author:) }

    context "with no news in this project" do
      it_behaves_like "empty-state with action"
    end

    context "with news" do
      let!(:news_items) { create_list(:news, 3, project:, author:) }

      it "renders only this project’s news" do
        expect(rendered_component).to have_list_item(count: 3)
        expect(rendered_component).to have_list_item(position: 3) do |item|
          expect(item).to have_link href: project_news_path(project, news_items.first)
          expect(item).to have_content(/Added by .+ on \d{2}\/\d{2}\/\d{4} \d{2}:\d{2} [AP]M/)
          expect(item).to have_link href: user_path(author)
        end
      end
    end
  end

  context "when the project does not have the news module enabled" do
    let(:project) { project_red }
    let!(:news_item) { create(:news, project:, author:) }

    before do
      project.enabled_module_names -= %w[news]
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the user does not have permission to manage news" do
    let(:project) { project_red }
    let(:user) { create(:user) }

    # User has only view_news permission now
    it_behaves_like "empty-state without action"
  end
end
