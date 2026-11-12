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

RSpec.describe Admin::Settings::RepositoriesSettings::CheckoutForm, type: :forms do
  include ViewComponent::TestHelpers

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }
  let(:vendor) { :git }

  def vc_render_form
    render_in_view_context(described_class, form_arguments, vendor) do |described_class, form_arguments, vendor|
      primer_form_with(**form_arguments) do |f|
        f.fields_for(:repository_checkout_data) do |fo|
          fo.fields_for(vendor) do |fg|
            render(described_class.new(fg, vendor:))
          end
        end
      end
    end
  end

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do
    expect(rendered_form).to have_field "Show checkout instructions", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[repository_checkout_data][git][enabled]"
    end

    expect(rendered_form).to have_field "Checkout base URL", type: :url do |field|
      expect(field["name"]).to eq "settings[repository_checkout_data][git][base_url]"
    end

    expect(rendered_form).to have_field "Checkout instruction text", type: :textarea do |field|
      expect(field["name"]).to eq "settings[repository_checkout_data][git][text]"
    end
  end
end
