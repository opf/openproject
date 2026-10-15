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

RSpec.describe Backlogs::BacklogFilterButtonComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:sprint) { create(:sprint, project:) }

  current_user { user }

  describe "#filters_count" do
    it "excludes the sprint/bucket/inbox/project filters managed by the dedicated picker" do
      query = Query.new(project:, user:)
      query.add_filter(:sprint_id, "=", [sprint.id.to_s])
      query.add_filter(:backlog_inbox, "=", [OpenProject::Database::DB_VALUE_TRUE])

      expect(described_class.new(query:).filters_count).to eq(0)
    end

    it "counts generic attribute filters added via the panel" do
      query = Query.new(project:, user:)
      query.add_filter(:status_id, "o", [""])
      query.add_filter(:sprint_id, "=", [sprint.id.to_s])

      expect(described_class.new(query:).filters_count).to eq(1)
    end

    it "counts the subject quick-search filter, unlike the picker-controlled ones" do
      query = Query.new(project:, user:)
      query.add_filter(:subject, "~", ["foo"])
      query.add_filter(:sprint_id, "=", [sprint.id.to_s])

      expect(described_class.new(query:).filters_count).to eq(1)
    end
  end
end
