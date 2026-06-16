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

# Minimal wrapper to test SharedHelpers#journal_created_at_formatted_time
# without the routing dependencies of the full ItemComponent template.
class JournalCreatedAtFormattedTimeTestComponent < ApplicationComponent
  include ApplicationHelper
  include WorkPackages::ActivitiesTab::SharedHelpers

  def initialize(journal)
    super(nil)
    @journal = journal
  end

  def call
    journal_created_at_formatted_time(@journal)
  end
end

RSpec.describe WorkPackages::ActivitiesTab::Journals::ItemComponent, type: :component do
  include Redmine::I18n

  describe "activity anchor link date" do
    let(:created_at) { 3.days.ago.beginning_of_minute }
    let(:updated_at) { 1.day.ago.beginning_of_minute }
    let(:journal) { build_stubbed(:work_package_journal, created_at:, updated_at:) }

    context "when a journal has been edited (updated_at differs from created_at)" do
      it "shows created_at rather than updated_at in the header link" do
        expect(format_time(created_at)).not_to eq(format_time(updated_at))

        render_inline(JournalCreatedAtFormattedTimeTestComponent.new(journal))

        expect(page).to have_text(format_time(created_at))
        expect(page).to have_no_text(format_time(updated_at))
      end
    end
  end
end
