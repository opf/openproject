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

RSpec.describe TestManagement::CiTriggers::TriggerContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs] }) }
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) do
    create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds an item")
  end
  shared_let(:manual) { create(:tm_test_case, project:, suite:) }
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

  let(:attributes) { { project:, connection:, suite: } }
  let(:request) { TestManagement::CiTriggers::Request.new(**attributes) }
  let(:user) { trigger_user }

  def errors
    contract = described_class.new(request, user)
    contract.validate
    request.errors
  end

  it "is valid for an automated folder" do
    expect(errors).to be_empty
  end

  it "needs the trigger_test_automation permission" do
    expect(described_class.new(request, viewer).tap(&:validate).errors.details[:base])
      .to include(error: :error_unauthorized)
  end

  context "with an unusable connection" do
    it "rejects a missing or foreign connection" do
      attributes[:connection] = create(:tm_ci_connection, :github_trigger, project: other_project)
      expect(errors.details[:connection]).to include(error: :blank)
    end

    it "rejects an inactive connection" do
      connection.update_columns(active: false)
      expect(errors.details[:connection]).to include(error: :inactive)
    ensure
      connection.update_columns(active: true)
    end

    it "names what is missing" do
      attributes[:connection] = create(:tm_ci_connection, project:, repository: "my-org/other")
      expect(errors.details[:connection].first).to include(error: :not_ready)
    end
  end

  it "is rejected while CI is disabled for the project" do
    create(:tm_project_setting, project:, options: { "enable_ci" => false })

    expect(errors.details[:base]).to include(error: :tm_ci_disabled)
  end

  it "needs exactly one scope and a known mode" do
    attributes.delete(:suite)
    expect(errors.details[:base]).to include(error: :tm_ci_scope_missing)

    attributes.merge!(suite:, test_case: automated)
    request = TestManagement::CiTriggers::Request.new(**attributes)
    described_class.new(request, user).validate
    expect(request.errors.details[:base]).to include(error: :tm_ci_scope_ambiguous)

    request = TestManagement::CiTriggers::Request.new(project:, connection:, suite:, mode: "sometimes")
    described_class.new(request, user).validate
    expect(request.errors.details[:mode]).to include(error: :inclusion)
  end

  it "needs at least one automated case" do
    attributes.merge!(suite: nil, test_case: manual)
    expect(errors.details[:base]).to include(error: :tm_ci_no_automated_cases)
  end

  it "needs an open run of the project for new_iteration" do
    attributes[:mode] = "new_iteration"
    expect(errors.details[:run]).to include(error: :blank)

    attributes[:run] = create(:tm_test_run, :completed, project:)
    expect(TestManagement::CiTriggers::Request.new(**attributes).tap { described_class.new(it, user).validate }
             .errors.details[:run]).to include(error: :tm_run_finished)

    attributes[:run] = create(:tm_test_run, project: other_project)
    expect(TestManagement::CiTriggers::Request.new(**attributes).tap { described_class.new(it, user).validate }
             .errors.details[:run]).to include(error: :blank)
  end

  it "validates the ref" do
    attributes[:ref] = "main && curl evil"
    expect(errors.details[:ref]).to include(error: :invalid)
  end
end
