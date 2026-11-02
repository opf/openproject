# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::AssistantMessages::ClearService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases use_test_assistant]
           })
  end

  it "deletes the user's messages in the project" do
    create(:tm_assistant_message, project:, user:)
    create(:tm_assistant_message, project:, user:)

    result = described_class.new(user:, project:).call

    expect(result).to be_success
    expect(TestManagement::AssistantMessage.of(user, project)).to be_empty
  end
end
