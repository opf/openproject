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

RSpec.describe Projects::SetAttributesService, "backlogs done_status_ids merging", type: :model do
  let(:user) { build_stubbed(:user) }
  let(:considered_closed_statuses) { [] }
  let(:project) do
    create(:project,
           enabled_module_names: ["backlogs"],
           backlog_considered_closed_statuses: considered_closed_statuses)
  end

  let(:contract_class) do
    contract = class_double(Projects::UpdateContract)
    allow(contract)
      .to receive(:new)
      .and_return(instance_double(Projects::UpdateContract, validate: true, errors: ActiveModel::Errors.new(project)))
    contract
  end

  let(:instance) { described_class.new(user:, model: project, contract_class:) }

  context "when done_status_ids is submitted" do
    let!(:closed_status) { create(:status, is_closed: true) }
    let!(:open_status) { create(:status, is_closed: false) }

    it "merges mandatory closed statuses alongside the submitted ones" do
      instance.call(done_status_ids: [open_status.id])

      expect(project.done_status_ids).to include(open_status.id)
      expect(project.done_status_ids).to include(closed_status.id)
    end

    it "does not duplicate a closed status already present in the submitted ids" do
      instance.call(done_status_ids: [closed_status.id])

      expect(project.done_status_ids.count(closed_status.id)).to eq(1)
    end

    it "keeps submitted non-closed statuses even when there are no globally closed statuses" do
      Status.where(is_closed: true).delete_all

      instance.call(done_status_ids: [open_status.id])

      expect(project.done_status_ids).to contain_exactly(open_status.id)
    end
  end

  context "when done_status_ids is not submitted" do
    let!(:closed_status) { create(:status, is_closed: true) }
    let(:considered_closed_statuses) { [closed_status] }

    it "does not modify the existing done_status_ids" do
      instance.call(name: "New Name")

      expect(project.done_status_ids).to contain_exactly(closed_status.id)
    end
  end
end
