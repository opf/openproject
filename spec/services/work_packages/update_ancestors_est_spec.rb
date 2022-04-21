require 'spec_helper'

describe WorkPackages::UpdateAncestorsService, type: :model, with_mail: false do
  let(:user) { create :user }
  let(:estimated_hours) { [nil, nil, nil] }
  let(:done_ratios) { [0, 0, 0] }
  let(:statuses) { %i(open open open) }
  let(:open_status) { create :status }
  let(:closed_status) { create :closed_status }
  let(:aggregate_done_ratio) { 0.0 }

  context 'with a common ancestor' do
    let(:status) { open_status }
    let(:done_ratio) { 50 }
    let(:estimated_hours) { 7.0 }

    let!(:grandparent) do
      create :work_package,
             derived_estimated_hours: estimated_hours,
             done_ratio: done_ratio
    end
    let!(:old_parent) do
      create :work_package,
             parent: grandparent,
             derived_estimated_hours: estimated_hours,
             done_ratio: done_ratio
    end
    let!(:new_parent) do
      create :work_package,
             parent: grandparent
    end
    let!(:work_package) do
      create :work_package,
             parent: old_parent,
             status: status,
             estimated_hours: estimated_hours,
             done_ratio: done_ratio
    end

    subject do
      # binding.pry
      work_package.parent = new_parent
      # In this test case, derived_estimated_hours and done_ratio will not
      # inherently change on grandparent.  However, if work_package has siblings
      # then changing its parent could cause derived_estimated_hours and/or
      # done_ratio on grandparent to inherently change.  To verify that
      # grandparent can be properly updated in that case without making this
      # test dependent on the implementation details of the
      # derived_estimated_hours and done_ratio calculations, force
      # derived_estimated_hours and done_ratio to change at the same time as the
      # parent.
      work_package.estimated_hours = (estimated_hours + 1)
      work_package.done_ratio = (done_ratio + 1)
      work_package.save!

      described_class
        .new(user: user,
             work_package: work_package)
        .call(%i(parent))
    end

    before do
      subject
    end

    it 'is successful' do
      expect(subject)
        .to be_success
    end

    it 'returns both the former and new ancestors in the dependent results without duplicates' do
      expect(subject.dependent_results.map(&:result))
        .to match_array [new_parent, grandparent, old_parent]
    end

    it 'updates the done_ratio of the former parent' do
      expect(old_parent.reload(select: :done_ratio).done_ratio)
        .to be 0
    end

    it 'updates the estimated_hours of the former parent' do
      expect(old_parent.reload(select: :derived_estimated_hours).derived_estimated_hours)
        .to be_nil
    end
  end
end
