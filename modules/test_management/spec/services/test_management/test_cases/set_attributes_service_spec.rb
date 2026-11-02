# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::SetAttributesService do
  # work_package_tracking: without it no work package of the project is visible, so the
  # link visibility check would (correctly) reject the new link.
  let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases edit_test_cases view_work_packages] })
  end

  def call(model, params, contract = TestManagement::TestCases::UpdateContract)
    described_class.new(user:, model:, contract_class: contract).call(params)
  end

  describe "labels" do
    let(:test_case) { create(:tm_test_case, project:) }

    it "creates project labels from a comma-separated list, de-duplicated case-insensitively" do
      result = call(test_case, { label_names: " smoke, Regression ,SMOKE,, " })
      test_case.save!

      expect(result).to be_success
      expect(test_case.reload.labels.map(&:name)).to contain_exactly("smoke", "Regression")
      expect(TestManagement::Label.where(project:).count).to eq(2)
    end

    it "reuses existing labels case-insensitively" do
      existing = create(:tm_label, project:, name: "Smoke")
      call(test_case, { label_names: "smoke" })
      test_case.save!

      expect(test_case.reload.labels).to eq([existing])
    end

    it "removes labels no longer listed and records the change in the history" do
      call(test_case, { label_names: "a, b" })
      test_case.save!
      fresh = TestManagement::TestCase.find(test_case.id)
      call(fresh, { label_names: "b, c" })

      expect(fresh.label_links_changed?).to be(true)
      fresh.save!

      expect(fresh.reload.labels.map(&:name)).to contain_exactly("b", "c")
      expect(fresh.events.last.details["labels"]).to eq("added" => ["c"], "removed" => ["a"])
    end

    it "keeps labels when the field is not submitted" do
      call(test_case, { label_names: "keep" })
      test_case.save!
      call(test_case, { title: "Other" })
      test_case.save!

      expect(test_case.reload.labels.map(&:name)).to eq(["keep"])
    end

    it "removes every label for an empty value" do
      call(test_case, { label_names: "x" })
      test_case.save!
      call(test_case, { label_names: "" })
      test_case.save!

      expect(test_case.reload.labels).to be_empty
    end
  end

  describe "work package links the user cannot see" do
    let(:other_project) { create(:project) }
    let(:hidden_wp) { create(:work_package, project: other_project) }
    let(:visible_wp) { create(:work_package, project:) }
    let(:new_wp) { create(:work_package, project:) }
    let(:test_case) do
      create(:tm_test_case, project:).tap do |tc|
        tc.test_case_work_packages.create!(work_package: hidden_wp)
        tc.test_case_work_packages.create!(work_package: visible_wp)
      end
    end

    it "keeps them when the submitted list (which only shows visible ones) omits them" do
      result = call(test_case.reload, { work_package_ids: [new_wp.id] })

      expect(result).to be_success
      result.result.save!
      expect(test_case.reload.test_case_work_packages.pluck(:work_package_id)).to contain_exactly(hidden_wp.id, new_wp.id)
    end
  end

  describe "editor tracking" do
    it "sets the author on create and the last editor on update" do
      test_case = project.tm_test_cases.build
      call(test_case, { title: "New" }, TestManagement::TestCases::CreateContract)
      test_case.save!
      expect(test_case.author).to eq(user)
      expect(test_case.updated_by).to be_nil

      editor = create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] })
      result = described_class.new(user: editor, model: test_case, contract_class: TestManagement::TestCases::UpdateContract)
                              .call({ title: "Changed" })
      test_case.save!

      expect(result).to be_success
      expect(test_case.reload.updated_by).to eq(editor)
    end
  end
end
