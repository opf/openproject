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
require Rails.root.join("lookbook/previews/open_project/common/border_box_list_collection_component_preview").to_s

RSpec.describe OpenProject::Common::BorderBoxListCollectionComponentPreview, type: :component do
  # The `default` example composes a nested BorderBoxListComponent per row,
  # which needs a real Rails `render` call inside the captured slot block —
  # `ViewComponent::Preview#render` only builds a component tree when
  # returned from the top of a preview method, so nested composition uses
  # `render_with_template` (an `.html.erb` sibling) instead. Resolving that
  # template requires `lookbook/previews` on the ViewComponent previews path,
  # which the app only adds when `lookbook_enabled?` (development only, see
  # `config/initializers/lookbook.rb`) — add it for this example only.
  around do |example|
    previews_config = Rails.application.config.view_component.previews
    lookbook_previews_path = Rails.root.join("lookbook/previews").to_s
    added = previews_config.paths.exclude?(lookbook_previews_path)
    previews_config.paths << lookbook_previews_path if added

    begin
      example.run
    ensure
      previews_config.paths.delete(lookbook_previews_path) if added
    end
  end

  it "renders the default preview as a page-level root wrapping two section boxes" do
    render_preview(:default, from: described_class)

    expect(page).to have_css("#border-box-list-collection-preview[data-controller~='sortable-lists']")
    expect(page).to have_css(
      "#border-box-list-collection-preview [data-controller~='sortable-lists--list']", count: 3
    )
    expect(page).to have_heading("Team information", level: 4)
    expect(page).to have_heading("Delivery details", level: 4)
    expect(page).to have_text("Team size")
    expect(page).to have_text("Release owner")
  end
end
