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

RSpec.describe Backlogs::SelectionDescriptionComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new) && page }

  # `visible: :all` because the element is permanently `hidden`, which is the
  # one form of invisibility Capybara::Node::Simple does honour.

  it "renders the description every selected card points at" do
    expect(rendered_component)
      .to have_css("##{described_class::DESCRIPTION_ID}", text: I18n.t("js.backlogs.selection.card_state"),
                                                          visible: :all)
  end

  # `hidden` keeps this out of the planning columns' layout: reserving space
  # above two independently scrolling columns moved the cards under the user's
  # cursor mid-drag.
  it "keeps the description hidden, since only aria-describedby reaches it" do
    expect(rendered_component).to have_css("##{described_class::DESCRIPTION_ID}[hidden]", visible: :all)
  end
end
