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
require Rails.root.join("spec/services/principals/replace_references_context")

RSpec.describe Principals::ReplaceReferencesService, "#call", type: :model do
  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  shared_let(:other_user) { create(:user, firstname: "other user") }
  shared_let(:principal) { create(:user, firstname: "old principal") }
  shared_let(:to_principal) { create(:user, firstname: "new principal") }

  let(:instance) { described_class.new }

  context "with TestManagement::TestCase" do
    it_behaves_like "rewritten record", :tm_test_case, :author_id
    it_behaves_like "rewritten record", :tm_test_case, :assigned_to_id
    it_behaves_like "rewritten record", :tm_test_case, :updated_by_id
  end

  context "with TestManagement::TestRun" do
    it_behaves_like "rewritten record", :tm_test_run, :author_id
    it_behaves_like "rewritten record", :tm_test_run, :assigned_to_id
    it_behaves_like "rewritten record", :tm_test_run, :finished_by_id
  end

  context "with TestManagement::TestRunCase" do
    it_behaves_like "rewritten record", :tm_test_run_case, :assigned_to_id
  end

  context "with TestManagement::TestResult" do
    it_behaves_like "rewritten record", :tm_test_result, :user_id
  end

  context "with TestManagement::AutomationImport" do
    it_behaves_like "rewritten record", :tm_automation_import, :user_id
  end

  context "with TestManagement::CiConnection" do
    it_behaves_like "rewritten record", :tm_ci_connection, :created_by_id
  end

  context "with TestManagement::TestRunIteration" do
    it_behaves_like "rewritten record", :tm_test_run_iteration, :created_by_id
  end
end
