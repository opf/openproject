require File.expand_path('../../../spec_helper', __FILE__)

describe ReportedProjectStatus do
  describe '- Relations ' do
    describe '#reportings' do
      it 'can read reportings w/ the help of the has_many association' do
        reported_project_status = FactoryGirl.create(:reported_project_status)
        reporting               = FactoryGirl.create(:reporting,
                                                 :reported_project_status_id => reported_project_status.id)

        reported_project_status.reload

        reported_project_status.reportings.size.should == 1
        reported_project_status.reportings.first.should == reporting
      end
    end
  end
end
