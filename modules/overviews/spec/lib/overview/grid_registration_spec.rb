require "spec_helper"

RSpec.describe Overviews::GridRegistration do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:grid) { build_stubbed(:overview, project:) }

  describe "writable?" do
    let(:permissions) { %i[manage_overview view_project] }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *permissions, project:
      end
    end

    context "if the user has the :manage_overview permission" do
      it "is truthy" do
        expect(described_class)
          .to be_writable(grid, user)
      end
    end

    context "if the user lacks the :manage_overview permission and it is a persisted page" do
      let(:permissions) { %i[view_project] }

      it "is falsey" do
        expect(described_class)
          .not_to be_writable(grid, user)
      end
    end

    context "if the user lacks the :manage_overview permission and it is a new record" do
      let(:permissions) { %i[view_project] }
      let(:grid) { Grids::Overview.new **attributes_for(:overview).merge(project:) }

      it "is truthy" do
        expect(described_class)
          .to be_writable(grid, user)
      end
    end
  end
end
