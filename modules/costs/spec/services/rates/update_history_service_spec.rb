# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rates::UpdateHistoryService do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:admin) { create(:admin) }
  shared_let(:principal) { create(:user) }

  subject(:service_result) do
    described_class
      .new(user: current_user, principal:, project: scoped_project)
      .call(new_rate_attributes:, existing_rate_attributes:)
  end

  let(:current_user) { admin }
  let(:scoped_project) { nil }
  let(:new_rate_attributes) { {} }
  let(:existing_rate_attributes) { {} }

  describe "default rates" do
    context "when adding a rate" do
      let(:new_rate_attributes) { { "0" => { valid_from: "2026-01-01", rate: "95" } } }

      it "creates it" do
        expect { service_result }.to change { principal.default_rates.count }.from(0).to(1)
        expect(service_result).to be_success
        expect(principal.default_rates.sole.rate).to eq(95)
      end
    end

    context "when the rate is written with a thousands delimiter" do
      let(:new_rate_attributes) { { "0" => { valid_from: "2026-01-01", rate: "1,234.50" } } }

      it "parses it rather than casting it to 1.0" do
        service_result

        expect(principal.default_rates.sole.rate).to eq(1234.5)
      end
    end

    context "when a row is left out of the submission" do
      let!(:existing) { create(:default_hourly_rate, principal:) }

      it "deletes the rate rather than orphaning it" do
        expect { service_result }.to change { principal.default_rates.count }.from(1).to(0)
        expect(DefaultHourlyRate.where(id: existing.id)).not_to exist
      end
    end

    context "when the acting user is not an admin" do
      let(:current_user) { create(:user) }
      let(:new_rate_attributes) { { "0" => { valid_from: "2026-01-01", rate: "95" } } }

      it "is refused" do
        expect { service_result }.not_to change { principal.default_rates.count }
        expect(service_result).to be_failure
        expect(service_result.includes_error?(:base, :error_unauthorized)).to be true
      end
    end
  end

  describe "project rates" do
    let(:scoped_project) { project }

    shared_let(:existing) { create(:hourly_rate, principal:, project:, rate: 50, valid_from: Date.new(2026, 1, 1)) }
    shared_let(:elsewhere) { create(:hourly_rate, principal:, project: other_project, rate: 70) }

    context "when updating an existing rate" do
      let(:existing_rate_attributes) do
        { existing.id.to_s => { valid_from: "2026-02-01", rate: "55" } }
      end

      it "applies the new values" do
        expect(service_result).to be_success

        expect(existing.reload).to have_attributes(rate: 55, valid_from: Date.new(2026, 2, 1))
      end

      it "does not create another rate" do
        expect { service_result }.not_to change { principal.rates.where(project:).count }
      end
    end

    context "when a rate in another project is submitted" do
      let(:existing_rate_attributes) do
        { elsewhere.id.to_s => { valid_from: "2026-02-01", rate: "99" } }
      end

      it "leaves that rate untouched" do
        expect { service_result }.not_to change { elsewhere.reload.rate }
      end

      it "still deletes the rates of the scoped project" do
        expect { service_result }.to change { principal.rates.where(project:).count }.from(1).to(0)
      end
    end

    context "when one of several rates is invalid" do
      let(:existing_rate_attributes) do
        { existing.id.to_s => { valid_from: "2026-02-01", rate: "55" } }
      end
      let(:new_rate_attributes) do
        { "0" => { valid_from: "2026-03-01", rate: "not a number" } }
      end

      it "rolls the whole submission back" do
        expect(service_result).to be_failure

        expect(existing.reload).to have_attributes(rate: 50, valid_from: Date.new(2026, 1, 1))
        expect(principal.rates.where(project:).count).to eq(1)
      end
    end

    context "when the acting user only has edit_own_hourly_rate" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => %i[edit_own_hourly_rate] })
      end

      context "and edits their own rate" do
        let(:principal) { current_user }
        let!(:own_rate) { create(:hourly_rate, principal: current_user, project:, rate: 40) }
        let(:existing_rate_attributes) { { own_rate.id.to_s => { valid_from: "2026-02-01", rate: "45" } } }

        it "is allowed" do
          expect(service_result).to be_success
          expect(own_rate.reload.rate).to eq(45)
        end
      end

      context "and edits someone else's rate" do
        let(:existing_rate_attributes) do
          { existing.id.to_s => { valid_from: "2026-02-01", rate: "55" } }
        end

        it "is refused" do
          expect(service_result).to be_failure
          expect(service_result.includes_error?(:base, :error_unauthorized)).to be true
          expect(existing.reload.rate).to eq(50)
        end
      end
    end
  end
end
