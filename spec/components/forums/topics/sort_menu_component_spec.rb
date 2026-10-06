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

RSpec.describe Forums::Topics::SortMenuComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new(forum:, sort_criteria:))
  end

  shared_let(:forum) { create(:forum) }

  let(:sort_criteria) do
    SortHelper::SortCriteria.new.tap do |criteria|
      criteria.available_criteria = %w[created_at replies updated_at]
      criteria.from_param("created_at")
    end
  end

  it "links every order to the forum with its sort param", :aggregate_failures do
    base = "/projects/#{forum.project.identifier}/forums/#{forum.id}"

    expect(rendered_component).to have_link("Recent activity", href: "#{base}?sort=updated_at%3Adesc", visible: :all)
    expect(rendered_component).to have_link("Oldest", href: "#{base}?sort=created_at", visible: :all)
    expect(rendered_component).to have_link("Most replies", href: "#{base}?sort=replies%3Adesc", visible: :all)
  end

  it "checks the current order only" do
    expect(rendered_component).to have_css("[aria-checked='true']", text: /\A\s*Oldest\s*\z/, count: 1, visible: :all)
  end
end
