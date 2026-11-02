# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::CaseMatcher do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project) }
  shared_let(:by_reference) do
    create(:tm_test_case, project:, title: "Sign in", automation_reference: "login.spec.ts#Login › signs in")
  end
  shared_let(:by_id) { create(:tm_test_case, project:, title: "Wrong password") }
  shared_let(:foreign) { create(:tm_test_case, project: other_project, title: "Foreign") }

  def record(**attrs)
    TestManagement::Automation::Record.new(raw_status: "passed", **attrs)
  end

  def match(rec, strategy: "auto")
    described_class.new(project:, strategy:).call([rec]).first
  end

  it "matches by the tm_case property first" do
    result = match(record(reference: "login.spec.ts#Login › signs in", properties: { "tm_case" => [by_id.id.to_s] }))

    expect(result.cases).to eq([by_id])
    expect(result.matched_by).to eq("property")
  end

  it "matches by the automation reference" do
    result = match(record(reference: "login.spec.ts#Login › signs in"))

    expect(result.cases).to eq([by_reference])
    expect(result.matched_by).to eq("reference")
  end

  it "matches ID tags and native case ids" do
    expect(match(record(reference: "x#y", tags: ["@TC-#{by_id.id}"])).cases).to eq([by_id])
    expect(match(record(case_ids: [by_id.id.to_s])).cases).to eq([by_id])
  end

  it "does not match titles unless asked to" do
    expect(match(record(title: "Wrong password")).cases).to be_empty
    expect(match(record(title: "wrong PASSWORD"), strategy: "title").cases).to eq([by_id])
  end

  it "explains why nothing matched" do
    expect(match(record(reference: "nothing#here")).reason).to eq("no_matching_case")
    expect(match(record(case_ids: [foreign.id.to_s])).reason).to eq("case_not_in_project")
  end

  it "ignores deleted cases" do
    by_reference.update_column(:deleted_at, Time.current)

    expect(match(record(reference: "login.spec.ts#Login › signs in")).cases).to be_empty
  end
end
