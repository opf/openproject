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
#
require "rails_helper"

RSpec.describe Portfolios::IndexComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let!(:portfolio_a) { create(:portfolio) }
  let!(:portfolio_b) { create(:portfolio) }

  let(:query) do
    create(:project_query)
  end

  let(:user) { create(:admin) }

  current_user { user }

  subject(:rendered_component) do
    render_component(query:, current_user: user)
  end

  describe "Portfolios" do
    context "when the query returns a result" do
      it "renders a list" do
        expect(subject).to have_test_selector("op-portfolios--portfolio-#{portfolio_a.id}")
        expect(subject).to have_test_selector("op-portfolios--portfolio-#{portfolio_b.id}")
      end

      it "does not render a placeholder" do
        expect(subject).not_to have_test_selector("op-portfolios--portfolios-placeholder")
      end
    end

    context "when the query does not return a result" do
      # For the purposes of this component, we do not care about projects. They will not show up in the view.
      let!(:portfolio_a) { create(:project) }
      let!(:portfolio_b) { create(:project) }

      it "does not render a list" do
        expect(subject).not_to have_test_selector("op-portfolios--portfolio-#{portfolio_a.id}")
        expect(subject).not_to have_test_selector("op-portfolios--portfolio-#{portfolio_b.id}")
      end

      it "renders a placeholder" do
        expect(subject).to have_test_selector("op-portfolios--portfolios-placeholder")
      end
    end
  end
end
