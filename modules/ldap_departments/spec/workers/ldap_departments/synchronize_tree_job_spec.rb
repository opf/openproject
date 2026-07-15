# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizeTreeJob, type: :job do
  let(:tree) { create(:ldap_synchronized_tree) }

  before { allow(LdapDepartments::SynchronizationService).to receive(:synchronize_tree!) }

  context "with the enterprise feature", with_ee: %i[ldap_groups] do
    it "synchronizes the given tree" do
      described_class.perform_now(tree)

      expect(LdapDepartments::SynchronizationService).to have_received(:synchronize_tree!).with(tree)
    end
  end

  context "without the enterprise feature" do
    it "does nothing" do
      described_class.perform_now(tree)

      expect(LdapDepartments::SynchronizationService).not_to have_received(:synchronize_tree!)
    end
  end
end
