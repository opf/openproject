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

RSpec.describe Enumeration, "anchor moves" do
  it "moves a priority below its anchor" do
    first = create(:issue_priority)
    second = create(:issue_priority)

    expect(first.move_after_anchor(second.id, scope: IssuePriority.all)).to be(true)
    expect(IssuePriority.reorder(:position).ids).to eq([second.id, first.id])
  end

  it "moves a document type to the top for a blank anchor" do
    first = create(:document_type)
    second = create(:document_type)

    expect(second.move_after_anchor("", scope: DocumentType.all)).to be(true)
    expect(DocumentType.reorder(:position).ids).to eq([second.id, first.id])
  end

  it "refuses an anchor from another enumeration class" do
    priority = create(:issue_priority)
    create(:issue_priority)
    activity = create(:time_entry_activity)
    original = IssuePriority.reorder(:position).ids

    expect(priority.move_after_anchor(activity.id, scope: IssuePriority.all)).to be(false)
    expect(IssuePriority.reorder(:position).ids).to eq(original)
  end
end
