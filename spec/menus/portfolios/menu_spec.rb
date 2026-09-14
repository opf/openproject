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

RSpec.describe Portfolios::Menu do
  let(:instance) { described_class.new(controller_path:, params:, current_user:) }
  let(:params) { {} }
  let(:current_user) { build(:admin) }

  subject(:menu_items) { instance.menu_items }

  describe "selected children items" do
    subject(:selected_menu_items) { menu_items.flat_map(&:children).select(&:selected) }

    context "when on portfolios page" do
      let(:controller_path) { "portfolios" }

      context "without params" do
        it "has active portfolios selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Active portfolios"))
        end
      end

      context "with query_id param for active portfolios" do
        let(:params) { { query_id: "active_portfolios" } }

        it "has active portfolios selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Active portfolios"))
        end
      end

      context "with query_id param for archived portfolios" do
        let(:params) { { query_id: "archived_portfolios" } }

        it "has archived portfolios selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "Archived portfolios"))
        end
      end

      context "with query_id param for my portfolios and filters in query" do
        let(:params) { { query_id: "my_portfolios", filters: "foo" } }

        it "has my portfolios selected" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with query_id param for my portfolios and sortBy in query" do
        let(:params) { { query_id: "my_portfolios", sortBy: "bar" } }

        it "has my portfolios selected" do
          expect(selected_menu_items).to be_empty
        end
      end

      context "with query_id param for my portfolios and columns in query (affects only for projects)" do
        let(:params) { { query_id: "my_portfolios", columns: "baz" } }

        it "has my portfolios selected" do
          expect(selected_menu_items).to contain_exactly(have_attributes(title: "My portfolios"))
        end
      end
    end

    context "when on portfolios/queries page" do
      let(:controller_path) { "portfolios/queries" }

      context "without params" do
        it "has no selected items" do
          expect(selected_menu_items).to be_empty
        end
      end
    end
  end
end
