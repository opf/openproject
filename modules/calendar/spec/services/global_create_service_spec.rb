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

RSpec.describe Calendar::Views::GlobalCreateService do
  shared_let(:project) { create(:project) }
  shared_let(:user) { build_stubbed(:admin) }
  shared_let(:instance) { described_class.new(user:) }

  subject { instance.call(params) }

  context "with all valid params" do
    let(:params) do
      {
        name: "Batman's Itinerary",
        project_id: project.id,
        public: true,
        starred: false
      }
    end

    it "is successful" do
      expect(subject).to be_success
    end

    it "creates a calendar view and its query" do
      view = subject.result
      query = view.query

      expect(view.type).to eq "work_packages_calendar"

      expect(query.name).to eq "Batman's Itinerary"
      expect(query.project).to eql(project)
      expect(query).to be_public
      expect(query).not_to be_starred
    end
  end
end
