# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCase do
  let(:project) { create(:project) }

  it "uses a global numeric primary key" do
    first = create(:tm_test_case, project:)
    second = create(:tm_test_case, project:)

    expect(first.id).to be_a(Integer)
    expect(second.id).to be > first.id
  end

  it "soft-deletes without freeing the id" do
    test_case = create(:tm_test_case, project:)
    retained_id = test_case.id

    test_case.soft_delete!

    expect(test_case.reload.deleted_at).to be_present
    expect(described_class.not_deleted.find_by(id: retained_id)).to be_nil
    expect(described_class.unscoped.find(retained_id).id).to eq(retained_id)
  end

  it "accepts nested steps" do
    test_case = create(:tm_test_case, :with_steps, project:)
    expect(test_case.steps.count).to eq(2)
  end

  it "validates status and priority" do
    test_case = build(:tm_test_case, project:, status: "nope", priority: "extreme")
    expect(test_case).not_to be_valid
    expect(test_case.errors.attribute_names).to include(:status, :priority)
  end
end
