# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCaseEvent do
  let(:author) { create(:user) }
  let(:editor) { create(:user) }
  let(:test_case) { create(:tm_test_case, author:, status: "draft", title: "Original") }

  it "records a created event by the author" do
    expect(test_case.events.map { |e| [e.action, e.user] }).to eq([["created", author]])
  end

  it "records attribute and text changes by the last editor" do
    test_case.update!(title: "Renamed", description: "Text", updated_by: editor)

    event = test_case.events.reload.last
    expect(event.action).to eq("updated")
    expect(event.user).to eq(editor)
    expect(event.details).to eq("title" => %w[Original Renamed], "description" => true)
  end

  it "records step changes" do
    test_case.update!(steps_attributes: [{ position: 0, action: "Open", expected_result: "Shown" }])

    expect(test_case.events.reload.last.details).to eq("steps" => true)
  end

  it "does not record an event when nothing tracked changed" do
    test_case
    expect { test_case.reload.save! }.not_to change(described_class, :count)
  end

  it "is removed with the test case" do
    test_case
    expect { test_case.destroy }.to change(described_class, :count).to(0)
  end
end
