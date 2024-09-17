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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe DefaultHourlyRate do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:rate) do
    build(:default_hourly_rate, project:,
                                user:)
  end

  describe "#user" do
    describe "WHEN an existing user is provided" do
      before do
        rate.user = user
        rate.save!
      end

      it { expect(rate.user).to eq(user) }
    end

    describe "WHEN a non existing user is provided (i.e. the user is deleted)" do
      before do
        rate.user = user
        rate.save!
        user.destroy
        rate.reload
      end

      it { expect(rate.user).to eq(DeletedUser.first) }
    end
  end
end
