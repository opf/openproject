require 'spec_helper'

describe Activity::WorkPackageActivityProvider do
  let(:event_scope)               { 'work_packages' }
  let(:work_package_edit_event)   { 'work_package-edit' }
  let(:work_package_closed_event) { 'work_package-closed' }

  let(:user)          { FactoryGirl.create :admin }
  let(:status_closed) { FactoryGirl.create :closed_status }
  let(:work_package)  { FactoryGirl.build  :work_package }

  let(:subject) { Activity::WorkPackageActivityProvider.find_events(event_scope, user, Date.today, Date.tomorrow, {}).last.try :event_type }

  describe 'latest event' do
    context 'when a work package has been created' do
      before { work_package.save }

      it { should == work_package_edit_event }

      context 'and has been closed' do
        before { work_package.update_attributes status_id: status_closed.id }

        it { should == work_package_closed_event }
      end
    end
  end
end
