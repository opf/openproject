require 'spec_helper'

describe Activity::WorkPackageActivityProvider do
  let(:event_scope)               { 'work_packages' }
  let(:work_package_edit_event)   { 'work_package-edit' }
  let(:work_package_closed_event) { 'work_package-closed' }

  let(:user)          { FactoryGirl.create :admin }
  let(:role)          { FactoryGirl.create :role }
  let(:status_closed) { FactoryGirl.create :closed_status }
  let(:work_package)  { FactoryGirl.build  :work_package }
  let!(:workflow)     { FactoryGirl.create :workflow,
                                           old_status: work_package.status,
                                           new_status: status_closed,
                                           type_id: work_package.type_id,
                                           role: role }

  describe '#event_type' do
    describe 'latest event' do
      let(:subject) { Activity::WorkPackageActivityProvider.find_events(event_scope, user, Date.today, Date.tomorrow, {}).last.try :event_type }

      context 'when a work package has been created' do
        before { work_package.save! }

        it { should == work_package_edit_event }

        context 'and has been closed' do
          before do
            User.stub(:current).and_return(user)

            work_package.status = status_closed
            work_package.save!
          end

          it { should == work_package_closed_event }
        end
      end
    end
  end
end
