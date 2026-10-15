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

# Shared expectations for lists rendered through
# OpenProject::Common::BorderBoxListComponent.
#
# Asserts the heading is a real heading element rendered inside the
# +.Box-header+, not merely text that happens to appear somewhere.
RSpec.shared_examples_for "rendering Border Box List heading" do |text:, level: nil|
  it "renders Border Box List heading '#{text}'" do
    expect(rendered_component).to have_css(".Box-header") do |header|
      expect(header).to have_heading(text, **{ level: }.compact)
    end
  end
end

# Shared expectations for an itemless Border Box List: the component renders
# a single Blank Slate row in place of the list items.
RSpec.shared_examples_for "rendering an empty Border Box List" do |heading:, icon: nil, header: true|
  it_behaves_like("rendering Box", row_count: 0, header:)
  it_behaves_like("rendering Blank Slate", heading:, icon:)
end
