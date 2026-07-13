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

RSpec.describe Workflows::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(types)
  end

  shared_examples_for "rendering Border Box headings" do |text:|
    it "renders Border Box heading '#{text}'" do
      expect(rendered_component).to have_css ".Box-header", text:
    end
  end

  context "with no types" do
    let(:types) { create_list(:type, 0) }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box headings", text: "Type"
    it_behaves_like "rendering Blank Slate", heading: "Nothing to display"
  end

  context "with types" do
    let(:types) { create_list(:type, 2) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box headings", text: "Type"

    it "renders row content" do
      expect(rendered_component).to have_css("li", text: types.first.name) do |row|
        expect(row).to have_link(types.first.name, href: edit_workflow_path(types.first))
        expect(row).to have_link("Edit", href: edit_workflow_path(types.first))
        expect(row).to have_link("Copy", href: new_workflow_copy_path(types.first))
      end
      expect(rendered_component).to have_css("li", text: types.second.name) do |row|
        expect(row).to have_link(types.second.name, href: edit_workflow_path(types.second))
        expect(row).to have_link("Edit", href: edit_workflow_path(types.second))
        expect(row).to have_link("Copy", href: new_workflow_copy_path(types.second))
      end
    end
  end
end
