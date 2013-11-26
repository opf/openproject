require 'spec_helper'

describe ::Query::Results do
  let(:query) { FactoryGirl.build :query }
  let(:query_results) do
    ::Query::Results.new query, include: [:assigned_to, :type, :priority, :category, :fixed_version],
                                order: "work_packages.root_id DESC, work_packages.lft ASC"
  end

  describe '#work_package_count_by_group' do
    context 'when grouping by responsible' do
      before { query.group_by = 'responsible' }

      it 'should produce a valid SQL statement' do
        expect { query_results.work_package_count_by_group }.not_to raise_error ::Query::StatementInvalid
      end
    end
  end
end
