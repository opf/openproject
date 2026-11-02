# frozen_string_literal: true

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
      expect(errors.full_messages.join).to include("Workflow file", "Access token")
    end
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
