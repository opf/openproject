require 'spec_helper'

describe 'my/page' do
  let(:project)    { FactoryGirl.create :valid_project }
  let(:user)       { FactoryGirl.create :admin, :member_in_project => project }
  let(:issue)      { FactoryGirl.create :issue, :project => project, :author => user }
  let(:time_entry) { FactoryGirl.create :time_entry,
                                        :project => project,
                                        :user => user,
                                        :issue => issue,
                                        :hours => 1}

  before do
    assign(:user,    user)
    time_entry.spent_on = Date.today
    time_entry.save!
  end

  it 'renders the timelog block' do
    assign :blocks, {'top' => ['timelog'], 'left' => [], 'right' => []}

    render

    assert_select 'tr.time-entry td.subject' do |tr|
      tr.should have_link("#{issue.tracker.name} ##{issue.id}", :href => issue_path(issue))
    end
  end
end
