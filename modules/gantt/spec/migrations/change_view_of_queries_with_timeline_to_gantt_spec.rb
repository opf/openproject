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
require Rails.root.join("db/migrate/20231201085450_change_view_of_queries_with_timeline_to_gantt.rb")

RSpec.describe ChangeViewOfQueriesWithTimelineToGantt, type: :model do
  let!(:wp_query_with_timeline) do
    query = create(:query_with_view_work_packages_table)
    query.timeline_visible = true

    query.save!
    query
  end

  let!(:wp_query_without_timeline) do
    query = create(:query_with_view_work_packages_table)
    query.timeline_visible = false

    query.save!
    query
  end

  let!(:calendar_query) do
    query = create(:query_with_view_work_packages_calendar)
    # Doesn't make sense in the calendar but should not be migrated nevertheless
    query.timeline_visible = true

    query.save!
    query
  end

  context "when migrating up" do
    # Silencing migration logs, since we are not interested in that during testing
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

    it "changes the view type for (work package table) queries with enabled timeline" do
      expect { subject }
        .to change { View.where(query_id: wp_query_with_timeline.id).first.type }.from("work_packages_table").to("gantt")
      expect { subject }
        .not_to change { View.where(query_id: wp_query_without_timeline.id).first.type }
      expect { subject }
        .not_to change { View.where(query_id: calendar_query.id).first.type }
    end
  end

  context "when migrating down" do
    let!(:gantt_query) do
      query = create(:query_with_view_gantt)
      query.timeline_visible = true

      query.save!
      query
    end

    # Silencing migration logs, since we are not interested in that during testing
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.down } }

    it "changes the view type for (gantt table) queries" do
      expect { subject }
        .to change { View.where(query_id: gantt_query.id).first.type }.from("gantt").to("work_packages_table")
      expect { subject }
        .not_to change { View.where(query_id: wp_query_with_timeline.id).first.type }
      expect { subject }
        .not_to change { View.where(query_id: wp_query_without_timeline.id).first.type }
      expect { subject }
        .not_to change { View.where(query_id: calendar_query.id).first.type }
    end
  end
end
