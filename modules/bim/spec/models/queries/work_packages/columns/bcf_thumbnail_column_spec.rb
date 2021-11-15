require 'spec_helper'
require Rails.root + 'spec/models/queries/work_packages/columns/shared_query_column_specs'

describe Bim::Queries::WorkPackages::Columns::BcfThumbnailColumn, type: :model do
  let(:instance) { described_class.new(:query_column) }

  it_behaves_like 'query column'

  describe 'instances' do
    context 'bim edition', with_config: { edition: 'bim' } do
      it 'the bcf_thumbnail column exists' do
        expect(described_class.instances.map(&:name))
          .to include :bcf_thumbnail
      end
    end

    context 'vanilla edition' do
      it 'the bcf_thumbnail column does not exist' do
        expect(described_class.instances.map(&:name))
          .not_to include :bcf_thumbnail
      end
    end
  end
end
