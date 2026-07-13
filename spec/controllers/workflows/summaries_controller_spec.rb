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

RSpec.describe Workflows::SummariesController do
  current_user { build_stubbed(:admin) }

  describe "#show" do
    let(:counts) { [] }

    before do
      allow(Workflow)
        .to receive(:count_by_type_and_role)
        .and_return(counts)

      get :show
    end

    it "is successful" do
      expect(response)
        .to be_successful
    end

    context "when counts is empty" do
      it "assigns the workflows by type and role" do
        expect(assigns[:workflow_counts]).to eql counts
      end

      it "assigns roles" do
        expect(assigns[:roles]).to be_nil
      end
    end

    context "when counts is present" do
      let(:type) { build_stubbed(:type) }
      let(:project_role) { build_stubbed(:project_role) }
      let(:global_role) { build_stubbed(:global_role) }
      let(:counts) { [[type, [[project_role, 25], [global_role, 0]]]] }

      it "assigns the workflows by type and role" do
        expect(assigns[:workflow_counts]).to eql counts
      end

      it "assigns roles" do
        expect(assigns[:roles]).to contain_exactly(project_role, global_role)
      end
    end
  end
end
