require 'spec_helper'

describe Overviews::GridRegistration do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:grid) { build_stubbed(:overview, project: project) }

  describe 'writable?' do
    let(:allowed) { true }
    before do
      allow(user)
        .to receive(:allowed_to?)
        .with(:manage_overview, project)
        .and_return(allowed)
    end

    context 'if the user has the :manage_overview permission' do
      it 'is truthy' do
        expect(described_class.writable?(grid, user))
          .to be_truthy
      end
    end

    context 'if the user lacks the :manage_overview permission and it is a persisted page' do
      let(:allowed) { false }

      it 'is falsey' do
        expect(described_class.writable?(grid, user))
          .to be_falsey
      end
    end

    context 'if the user lacks the :manage_overview permission and it is a new record' do
      let(:allowed) { false }
      let(:grid) { Grids::Overview.new **attributes_for(:overview).merge(project: project) }

      it 'is truthy' do
        expect(described_class.writable?(grid, user))
          .to be_truthy
      end
    end
  end
end
