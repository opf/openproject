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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Sprints::Scopes::Preceding do
  shared_let(:project) { create(:project) }

  shared_let(:first) do
    create(:sprint, project:, name: "First", start_date: Date.new(2025, 8, 1), finish_date: Date.new(2025, 8, 21))
  end
  shared_let(:second) do
    create(:sprint, project:, name: "Second", start_date: Date.new(2025, 9, 1), finish_date: Date.new(2025, 9, 21))
  end
  shared_let(:third) do
    create(:sprint, project:, name: "Third", start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 21))
  end
  shared_let(:current) do
    create(:sprint, project:, name: "Current", start_date: Date.new(2025, 11, 1), finish_date: Date.new(2025, 11, 21))
  end

  it "hands back the sprints that began before, oldest first" do
    expect(Sprint.preceding(current, limit: 3)).to eq [first, second, third]
  end

  it "takes the nearest ones rather than the earliest when there are more than asked for" do
    expect(Sprint.preceding(current, limit: 2)).to eq [second, third]
  end

  it "hands back all of them when fewer have run than asked for" do
    expect(Sprint.preceding(second, limit: 6)).to eq [first]
  end

  it "is empty for the first sprint there ever was" do
    expect(Sprint.preceding(first, limit: 6)).to be_empty
  end

  it "composes with the scope it is called on" do
    other_project_sprint = create(:sprint, project: create(:project),
                                           name: "Elsewhere",
                                           start_date: Date.new(2025, 10, 15),
                                           finish_date: Date.new(2025, 10, 25))

    expect(Sprint.preceding(current, limit: 6)).to include other_project_sprint
    expect(Sprint.for_project(project).preceding(current, limit: 6)).not_to include other_project_sprint
  end

  # Where a sprint is listed is what makes it preceding, and a sprint that ran is listed before
  # one that was only ever planned, however late it ran.
  it "places a sprint that actually started ahead of the merely planned ones" do
    started_late = create(:sprint, project:, name: "Started late",
                                   start_date: Date.new(2025, 7, 1),
                                   finish_date: Date.new(2025, 7, 20),
                                   started_at: Time.zone.local(2025, 10, 20, 9))

    expect(Sprint.preceding(current, limit: 6)).to eq [started_late, first, second, third]
    expect(Sprint.preceding(current, limit: 1)).to eq [third]
  end

  it "counts a sprint sharing this one's dates when the order puts it first" do
    alongside = create(:sprint, project:, name: "Alongside",
                                start_date: current.start_date,
                                finish_date: current.finish_date)

    expect(Sprint.preceding(current, limit: 6)).to include alongside
  end

  context "with a sprint that has no dates at all" do
    shared_let(:undated) { create(:sprint, project:, name: "Undated", start_date: nil, finish_date: nil) }

    it "never counts as preceding, there being nothing to place it by" do
      expect(Sprint.preceding(current, limit: 6)).not_to include undated
    end

    it "has every dated sprint preceding it, being listed last itself" do
      expect(Sprint.preceding(undated, limit: 6)).to eq [first, second, third, current]
    end
  end

  # A sprint still running has no finish to be ordered by, which does not stop it having begun.
  it "counts a sprint that has begun but has no end" do
    open_ended = create(:sprint, project:, name: "Open ended",
                                 start_date: Date.new(2025, 10, 20),
                                 finish_date: nil)

    expect(Sprint.preceding(current, limit: 1)).to eq [open_ended]
  end
end
