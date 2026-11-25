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

RSpec.describe Sprints::Origin do
  subject(:sprint) { build(:sprint, **origin) }

  let(:origin) do
    { origin_source: "jira_data_center", origin_id: "7", origin_host: "https://jira.example.com/",
      origin_url: "https://jira.example.com/rest/agile/1.0/sprint/7" }
  end

  it "accepts a complete origin" do
    expect(sprint).to be_valid
  end

  context "without an origin" do
    let(:origin) { {} }

    it { is_expected.to be_valid }
  end

  it "rejects an unknown origin source" do
    sprint.origin_source = "trello"
    expect(sprint).not_to be_valid
    expect(sprint.errors[:origin_source]).to be_present
  end

  %i[origin_id origin_url origin_host].each do |attribute|
    it "requires #{attribute} when an origin source is set" do
      sprint.public_send(:"#{attribute}=", nil)
      expect(sprint).not_to be_valid
      expect(sprint.errors[attribute]).to be_present
    end
  end
end
