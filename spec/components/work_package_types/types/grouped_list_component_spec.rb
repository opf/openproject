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

RSpec.describe WorkPackageTypes::Types::GroupedListComponent, type: :component do
  include Rails.application.routes.url_helpers

  current_user { create(:admin) }

  describe "a variant-less root" do
    let(:root_type) { create(:type, name: "Task") }

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.where(id: root_type.id).page(1).per_page(10)))
      end
    end

    it "renders the group header but no generic empty state", :aggregate_failures do
      expect(rendered_component).to have_css("h4.Box-title", text: root_type.name)
      expect(rendered_component).to have_no_css("[data-empty-list-item]")
      expect(rendered_component).to have_no_css(".blankslate")
    end
  end
end
