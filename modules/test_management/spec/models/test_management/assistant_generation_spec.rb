# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::AssistantGeneration do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user) }

  describe "#usage_payload / #status_payload" do
    it "exposes stored token usage only when present" do
      generation = create(:tm_assistant_generation, :running, project:, user:)

      expect(generation.usage_payload).to be_nil
      expect(generation.status_payload).not_to have_key(:usage)

      generation.update!(status: "done",
                         usage: { "prompt_tokens" => 1, "completion_tokens" => 2, "total_tokens" => 3,
                                  "reasoning_tokens" => 0 })
      expect(generation.usage_payload).to eq("prompt_tokens" => 1, "completion_tokens" => 2,
                                             "total_tokens" => 3, "reasoning_tokens" => 0)
      expect(generation.status_payload[:usage]).to eq(generation.usage_payload)
    end
  end
end
