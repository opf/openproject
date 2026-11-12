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

RSpec.describe Widget::Controls::SaveAs, type: :component do
  include ViewComponent::TestHelpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:cost_query) { build_stubbed(:cost_report, public: true) }
  let(:options) { {} }

  subject(:rendered_component) do
    with_controller_class(Reporting::CostReportsController) do
      with_request_url("/reporting/cost_reports") do
        render_in_view_context(described_class, cost_query, self) do |described_class, model, spec_context|
          primer_form_with(model:, url: "") do |f|
            render(described_class.new(model, f, **spec_context.options))
          end
        end
      end
    end
  end

  context "when :can_save_as is false (default)" do
    it "does not render a button" do
      expect(rendered_component).to have_no_button text: "Save"
    end
  end

  context "when :can_save_as is true" do
    let(:options) { { can_save_as: true } }

    it "renders a button" do
      expect(rendered_component).to have_button text: "Save", type: "button"
    end
  end
end
