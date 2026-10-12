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

RSpec.describe AdminElevationSessions::EndService, type: :model do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:user) { admin }
  let(:elevation_session) { create(:admin_elevation_session, user: admin, project:) }

  subject(:result) { described_class.new(user:, model: elevation_session).call }

  it "ends the elevation session", :aggregate_failures do
    freeze_time do
      expect(result).to be_success
      expect(elevation_session.reload.ended_at).to eq(Time.current)
    end
  end

  context "with an elevation session that has already ended" do
    let(:ended_at) { 1.hour.ago.change(usec: 0) }
    let(:elevation_session) { create(:admin_elevation_session, user: admin, project:, ended_at:) }

    it "succeeds and keeps the original end", :aggregate_failures do
      expect(result).to be_success
      expect(result.result).to eq(elevation_session)
      expect(elevation_session.reload.ended_at).to eq(ended_at)
    end
  end

  context "for another admin" do
    let(:user) { create(:admin) }

    it "fails without ending the elevation session", :aggregate_failures do
      expect(result).to be_failure
      expect(elevation_session.reload.ended_at).to be_nil
    end

    context "with an elevation session that has already ended" do
      let(:ended_at) { 1.hour.ago.change(usec: 0) }
      let(:elevation_session) { create(:admin_elevation_session, user: admin, project:, ended_at:) }

      it "fails and keeps the original end", :aggregate_failures do
        expect(result).to be_failure
        expect(elevation_session.reload.ended_at).to eq(ended_at)
      end
    end
  end
end
