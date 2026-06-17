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

RSpec.describe Backlogs::CommonHelper do
  describe "#user_allowed?" do
    let(:user) { build_stubbed(:user) }
    let(:default_project) { build_stubbed(:project) }
    let(:explicit_project) { build_stubbed(:project) }

    before do
      without_partial_double_verification do
        allow(helper).to receive_messages(current_user: user, project: default_project)
      end

      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:create_sprints, project: explicit_project)
      end
    end

    it "checks permissions in the provided project when given" do
      expect(helper.user_allowed?(:create_sprints, project: explicit_project)).to be true
    end

    it "checks permissions in the default project when none is given" do
      expect(helper.user_allowed?(:create_sprints)).to be false
    end
  end

  describe "#show_all_backlog" do
    before do
      allow(helper).to receive(:params).and_return(params)
    end

    context "when the all param is absent" do
      let(:params) { {} }

      it "is false" do
        expect(helper.show_all_backlog).to be false
      end
    end

    context "when the all param is a Rails boolean truthy string" do
      let(:params) { { all: "1" } }

      it "is true" do
        expect(helper.show_all_backlog).to be true
      end
    end

    context "when the all param is the string false" do
      let(:params) { { all: "false" } }

      it "is false" do
        expect(helper.show_all_backlog).to be false
      end
    end

    context "when the all param is the string zero" do
      let(:params) { { all: "0" } }

      it "is false" do
        expect(helper.show_all_backlog).to be false
      end
    end
  end

  describe "#all_backlogs_params" do
    before do
      allow(helper).to receive(:params).and_return(params)
    end

    context "when show_all_backlog is true" do
      let(:params) { { all: "1" } }

      it "returns the all query hash" do
        expect(helper.all_backlogs_params).to eq({ all: 1 })
      end
    end

    context "when show_all_backlog is false" do
      let(:params) { {} }

      it "returns an empty hash" do
        expect(helper.all_backlogs_params).to eq({})
      end
    end
  end
end
