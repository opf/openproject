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

RSpec.describe Backlogs::WorkPackages::BatchMoveParamsContract do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user) }

  def contract(params)
    described_class.new(project, user, params:)
  end

  it "accepts distinct ids, a resolvable target and a numeric predecessor" do
    expect(contract(ids: %w[1 2], list_type: "sprint", list_id: "3", prev_id: "4")).to be_valid
  end

  it "accepts a blank and an absent predecessor" do
    expect(contract(ids: %w[1], list_type: "inbox", prev_id: "")).to be_valid
    expect(contract(ids: %w[1], list_type: "inbox")).to be_valid
  end

  it "rejects blank or duplicate ids" do
    expect(contract(ids: ["1", ""], list_type: "inbox")).not_to be_valid

    duplicate = contract(ids: %w[1 1], list_type: "inbox")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors.full_messages)
      .to include(I18n.t("backlogs.work_packages.move_collection.invalid_ids"))
  end

  it "keeps its errors off the project" do
    invalid = contract(ids: %w[1 1], list_type: "inbox")
    expect(invalid).not_to be_valid

    expect(project.errors).to be_empty
    expect(invalid.errors.full_messages).not_to be_empty
  end

  it "rejects an empty id list" do
    expect(contract(ids: [], list_type: "inbox")).not_to be_valid
  end

  it "rejects more ids than the cap" do
    ids = Array.new(Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE + 1) { |i| (i + 1).to_s }

    oversized = contract(ids:, list_type: "inbox")
    expect(oversized).not_to be_valid
    expect(oversized.errors.full_messages)
      .to include(I18n.t("backlogs.work_packages.move_collection.too_many_work_packages",
                         max: Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE))
  end

  it "rejects an unresolvable target" do
    unresolvable = contract(ids: %w[1], list_type: "sprint")
    expect(unresolvable).not_to be_valid
    expect(unresolvable.errors.full_messages)
      .to include(I18n.t("backlogs.work_packages.update_service.invalid_target_type"))
  end

  it "rejects a malformed predecessor instead of integer-casting it" do
    malformed = contract(ids: %w[1], list_type: "inbox", prev_id: "12abc")
    expect(malformed).not_to be_valid
    expect(malformed.errors.full_messages)
      .to include(I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor"))
  end

  it "rejects a predecessor that is part of the batch" do
    expect(contract(ids: %w[1 2], list_type: "inbox", prev_id: "2")).not_to be_valid
  end
end
