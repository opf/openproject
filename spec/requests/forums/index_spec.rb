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

RSpec.describe "Forums index", type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_messages manage_forums] }) }

  current_user { manager }

  def add_forums_with_a_message(count)
    create_list(:forum, count, project:).each do |forum|
      message = create(:message, forum:)
      forum.update_column(:last_message_id, message.id)
    end
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  it "lists forums with their last message and row actions without querying per forum" do
    # Counts cached lookups too: those repeat per row even when the database is spared.
    add_forums_with_a_message(2)
    get project_forums_path(project)
    baseline = count_queries { get project_forums_path(project) }

    add_forums_with_a_message(3)

    expect(count_queries { get project_forums_path(project) }).to be <= baseline
  end
end
