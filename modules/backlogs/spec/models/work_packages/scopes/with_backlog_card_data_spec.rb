# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe WorkPackages::Scopes::WithBacklogCardData do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:work_package) { create(:work_package, project:) }

  current_user { user }

  subject(:scoped) { WorkPackage.where(id: work_package.id).with_backlog_card_data.first }

  describe ".with_backlog_card_data" do
    context "when the backlogs_lazy_cards feature is enabled", with_flag: { backlogs_lazy_cards: true } do
      it "projects the card_hash (delegates to with_card_hash)" do
        expect(scoped.card_hash).to match(/\A\h{32}\z/)
      end
    end

    context "when the backlogs_lazy_cards feature is disabled", with_flag: { backlogs_lazy_cards: false } do
      it "does not project a card_hash but eager loads the card associations" do
        expect(scoped.read_attribute(:card_hash)).to be_nil
        expect(scoped.association(:status)).to be_loaded
        expect(scoped.association(:type)).to be_loaded
        expect(scoped.association(:assigned_to)).to be_loaded
        expect(scoped.association(:priority)).to be_loaded
        expect(scoped.association(:parent)).to be_loaded
      end
    end
  end
end
