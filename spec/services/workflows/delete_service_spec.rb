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

RSpec.describe Workflows::DeleteService do
  shared_let(:admin) { create(:admin) }

  let(:replacement) { create(:named_workflow, name: "Replacement") }

  subject(:service) { described_class.new(user: admin, model: workflow) }

  context "when no variant uses the workflow" do
    let(:workflow) { create(:named_workflow) }

    it "deletes it" do
      expect(service.call(target: nil)).to be_success
      expect { workflow.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when variants use the workflow" do
    let(:workflow) { create(:named_workflow) }
    let!(:variant) { create(:type, name: "Bug").default_variant.tap { it.update!(workflow:) } }

    context "without a replacement" do
      it "refuses, leaving the workflow and the variant on it" do
        expect(service.call(target: nil)).to be_failure
        expect(workflow.reload).to be_present
        expect(variant.reload.workflow).to eq(workflow)
      end
    end

    context "with a replacement" do
      it "repoints every variant to it and deletes the workflow" do
        expect(service.call(target: replacement)).to be_success
        expect { workflow.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(variant.reload.workflow).to eq(replacement)
      end
    end
  end
end
