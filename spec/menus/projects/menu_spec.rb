# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Projects::Menu do
  let(:instance) { described_class.new(controller_path:, params:, current_user:) }
  let(:controller_path) { "foo" }
  let(:params) { {} }

  shared_let(:current_user) { build(:user) }

  shared_let(:current_user_query) do
    ProjectQuery.create!(name: "Current user query", user: current_user)
  end

  shared_let(:other_user_query) do
    ProjectQuery.create!(name: "Other user query", user: build(:user))
  end

  shared_let(:public_query) do
    ProjectQuery.create!(name: "Public query", user: build(:user), public: true)
  end

  subject(:menu_items) { instance.menu_items }

  it "returns 4 menu groups" do
    expect(menu_items).to all(be_a(OpenProject::Menu::MenuGroup))
    expect(menu_items.length).to eq(4)
  end

  describe "children items" do
    subject(:children_menu_items) { menu_items.flat_map(&:children) }

    context "when the current user is an admin" do
      before do
        allow(current_user).to receive(:admin?).and_return(true)
      end

      it "has an archived projects item" do
        expect(children_menu_items).to include(have_attributes(title: I18n.t("projects.lists.archived")))
      end
    end

    context "when the current user is not an admin" do
      before do
        allow(current_user).to receive(:admin?).and_return(false)
      end

      it "has an archived projects item" do
        expect(children_menu_items).not_to include(have_attributes(title: I18n.t("projects.lists.archived")))
      end
    end

    it "contains menu items" do
      expect(children_menu_items).to all(be_a(OpenProject::Menu::MenuItem))
    end

    it "contains item for current user query" do
      expect(children_menu_items).to include(have_attributes(title: "Current user query"))
    end

    it "doesn't contain item for other user query" do
      expect(children_menu_items).not_to include(have_attributes(title: "Other user query"))
    end

    it "contains item for public query" do
      expect(children_menu_items).to include(have_attributes(title: "Public query"))
    end
  end

  describe "selected children items" do
    subject(:selected_menu_items) { menu_items.flat_map(&:children).select(&:selected) }

    context "when on homescreen page" do
      let(:controller_path) { "homescreen" }

      context "without params" do
        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with query_id param" do
        let(:params) { { query_id: current_user_query.id.to_s } }

        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with id param" do
        let(:params) { { id: current_user_query.id.to_s } }

        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end
    end

    context "when on projects page" do
      let(:controller_path) { "projects" }

      context "without params" do
        it "has default item selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Active projects"))
        end
      end

      context "with id param" do
        let(:params) { { id: current_user_query.id.to_s } }

        it "has default item selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Active projects"))
        end
      end

      context "with query_id param for active projects" do
        let(:params) { { query_id: "active" } }

        it "has active projects selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Active projects"))
        end
      end

      context "with query_id param for at_risk projects" do
        let(:params) { { query_id: "at_risk" } }

        it "has active projects selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "At risk"))
        end
      end

      context "with query_id param for current user query" do
        let(:params) { { query_id: current_user_query.id.to_s } }

        it "has current user query selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Current user query"))
        end
      end

      context "with query_id param for active projects and modifications to query" do
        let(:params) { { query_id: "active", columns: "foo" } }

        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with query_id param for current user query and modifications to query" do
        let(:params) { { query_id: current_user_query.id.to_s, columns: "foo" } }

        it "has current user query selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Current user query"))
        end
      end
    end

    context "when on project queries page" do
      let(:controller_path) { "projects/queries" }

      context "without params" do
        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with query_id param" do
        let(:params) { { query_id: current_user_query.id.to_s } }

        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with id param for current user query" do
        let(:params) { { id: current_user_query.id.to_s } }

        it "has current user query selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Current user query"))
        end
      end
    end
  end
end
