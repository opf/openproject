
RSpec.shared_examples "status collection representer" do
  let(:statuses)  { FactoryGirl.build_list(:status, 3) }
  let(:models)    { statuses.map { |status|
    ::API::V3::Statuses::StatusModel.new(status)
  } }
  let(:representer) { described_class.new(models) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('Statuses'.to_json).at_path('_type') }

    it { should have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(subject).to have_json_path('_links/self/href')
    end

    describe 'statuses' do
      it { should have_json_path('_embedded/statuses') }
      it { should have_json_size(3).at_path('_embedded/statuses') }
      it { should have_json_path('_embedded/statuses/2/name') }
    end
  end
end
