# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herfy::ControlCenter do
  let(:user) { create(:user) }

  def field_value(name)
    user.reload.custom_values.joins(:custom_field).find_by(custom_fields: { name: })&.value
  end

  describe ".claims_from_export" do
    it "maps identity, reporting and org_profile into the same keys as the login claims" do
      record = {
        "identity" => { "empid" => "E1", "roles" => %w[hr lead] },
        "reporting" => { "manager_email" => "boss@herfy.com", "manager_name" => "Big Boss" },
        "org_profile" => { "company" => "Herfy Foods", "department" => "Ops", "designation" => "Analyst" }
      }

      expect(described_class.claims_from_export(record)).to eq(
        "empid" => "E1", "company" => "Herfy Foods", "roles" => %w[hr lead],
        "manager_email" => "boss@herfy.com", "manager_name" => "Big Boss",
        "department" => "Ops", "designation" => "Analyst"
      )
    end
  end

  describe ".apply_claims" do
    let(:claims) do
      { "empid" => "E1", "company" => "Herfy Foods", "roles" => %w[hr lead], "manager_email" => "boss@herfy.com",
        "manager_name" => "Big Boss", "department" => "Ops", "designation" => "Analyst" }
    end

    it "stores company, manager, department and the rest in custom fields" do
      described_class.apply_claims(user, claims)

      expect(field_value("Company")).to eq("Herfy Foods")
      expect(field_value("Manager")).to eq("Big Boss <boss@herfy.com>")
      expect(field_value("Department")).to eq("Ops")
      expect(field_value("Designation")).to eq("Analyst")
      expect(field_value("Role")).to eq("hr, lead")
      expect(field_value("Employee ID")).to eq("E1")
    end

    it "keeps stored values when a later login carries fewer claims" do
      described_class.apply_claims(user, claims)
      described_class.apply_claims(user, { "empid" => "E1" })

      expect(field_value("Department")).to eq("Ops")
      expect(field_value("Manager")).to eq("Big Boss <boss@herfy.com>")
    end
  end
end
