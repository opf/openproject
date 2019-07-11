require 'spec_helper'

describe Dashboards::GridRegistration do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:grid) { FactoryBot.build_stubbed(:dashboard, project: project) }

  describe 'from_scope' do
    context 'with a relative URL root', with_config: { rails_relative_url_root: '/foobar' } do
      subject { described_class.from_scope '/foobar/projects/an_id/dashboards' }

      it 'returns the class' do
        expect(subject[:class]).to eq(::Grids::Dashboard)
      end

      it 'returns the project_id' do
        expect(subject[:project_id]).to eq('an_id')
      end

      context 'with a different route' do
        subject { described_class.from_scope '/barfoo/projects/an_id/dashboards' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    context 'without a relative URL root' do
      subject { described_class.from_scope '/projects/an_id/dashboards' }

      it 'returns the class' do
        expect(subject[:class]).to eq(::Grids::Dashboard)
      end

      it 'returns the project_id' do
        expect(subject[:project_id]).to eq('an_id')
      end

      context 'with a different route' do
        subject { described_class.from_scope '/projects/an_id/boards' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe 'defaults' do
    it 'returns the initialized widget' do
      expect(described_class.defaults[:widgets].map(&:identifier))
        .to match_array ["work_packages_table"]
    end
  end

  describe 'writable?' do
    let(:allowed) { true }
    before do
      allow(user)
        .to receive(:allowed_to?)
        .with(:manage_dashboards, project)
        .and_return(allowed)
    end

    context 'if the user has the :manage_dashboards permission' do
      it 'is truthy' do
        expect(described_class.writable?(grid, user))
          .to be_truthy
      end
    end

    context 'if the user lacks the :manage_dashboards permission' do
      let(:allowed) { false }

      it 'is falsey' do
        expect(described_class.writable?(grid, user))
          .to be_falsey
      end
    end
  end
end
