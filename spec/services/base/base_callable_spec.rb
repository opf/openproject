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

RSpec.describe BaseServices::BaseCallable, type: :model do
  let(:test_service) do
    Class.new(BaseServices::BaseCallable) do
      def perform(*)
        state.test = "foo"
        ServiceResult.success(result: "something")
      end
    end
  end

  let(:test_service2) do
    Class.new(BaseServices::BaseCallable) do
      def perform(*)
        state.test2 = "foo"
        ServiceResult.success(result: "something")
      end
    end
  end

  let(:instance) { test_service.new }

  subject { instance.call }

  describe "state" do
    let(:result_state) { subject.state }

    it "is returned from the call", :aggregate_failures do
      expect(result_state).to be_a(Shared::ServiceState)
      expect(result_state.test).to eq "foo"
      expect(subject).to be_a ServiceResult
    end

    describe "with state already passed into the service" do
      let(:instance) { test_service.new.with_state(bar: "some value") }

      it "keeps that value", :aggregate_failures do
        expect(result_state).to be_a(Shared::ServiceState)
        expect(result_state.test).to eq "foo"
        expect(result_state.bar).to eq "some value"
      end
    end
  end
end
