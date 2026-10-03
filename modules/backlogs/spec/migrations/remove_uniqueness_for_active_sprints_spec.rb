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
require Rails.root.join("db/migrate/20260708203257_remove_uniqueness_for_active_sprints")
require Rails.root.join("modules/backlogs/db/migrate/20261002090000_remove_status_from_sprints")

RSpec.describe RemoveUniquenessForActiveSprints, type: :model do
  # In this test: RemoveStatusFromSprints has already run.
  # In production: it runs after RemoveUniquenessForActiveSprints.
  # The schema change is rolled back together with the example's transaction.
  before do
    ActiveRecord::Migration.suppress_messages { RemoveStatusFromSprints.migrate(:down) }
    Sprint.reset_column_information
  end

  after { Sprint.reset_column_information }

  describe "#down" do
    subject(:migrate) do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }
    end

    context "when no project has multiple active sprints" do
      it "does not raise any errors" do
        expect { migrate }.not_to raise_error(RuntimeError, /Cannot roll back/)
      end
    end

    context "when a project has multiple active sprints" do
      shared_let(:project) do
        create(:project, sprint_sharing: "no_sharing", allow_multiple_active_sprints: true)
      end

      shared_let(:sprints) { create_list(:sprint, 2, :active, project:) }

      it "raises an error describing which projects need cleanup" do
        expect { migrate }.to raise_error(RuntimeError, /Cannot roll back/)
      end
    end
  end
end
