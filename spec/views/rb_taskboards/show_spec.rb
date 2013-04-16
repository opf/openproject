require File.dirname(__FILE__) + '/../../spec_helper'

describe 'rb_taskboards/show' do
  let(:project)  { stub_model(Project) }
  let(:sprint)   { stub_model(Sprint) }
  let(:statuses) { [stub_model(IssueStatus, :name => 'Open'),
                    stub_model(IssueStatus, :name => 'In Progress'),
                    stub_model(IssueStatus, :name => 'Closed')] }

  let(:assignee) { stub_model(User, :firstname => 'Karl', :lastname => 'Gustav') }

  before :each do
    view.extend RbCommonHelper
    view.extend TaskboardsHelper

    assign(:project, project)
    assign(:sprint, sprint)
    assign(:statuses, statuses)
    assign(:all_issue_status, statuses)
  end

  describe 'story blocks' do
    let(:story_a) { story =
                    stub_model(Story, :id => 1001, :subject => 'Story A', :status_id => statuses[0].id, :assigned_to => assignee)
                    story.status = statuses[0]
                    story }
    let(:story_b) { story = stub_model(Story, :id => 1002, :subject => 'Story B', :status_id => statuses[1].id, :assigned_to => assignee)
                    story.status = statuses[1]
                    story }
    let(:story_c) { story = stub_model(Story, :id => 1003, :subject => 'Story C', :status_id => statuses[2].id, :assigned_to => assignee)
                    story.status = statuses[2]
                    story }
    let(:stories) { [story_a, story_b, story_c] }

    before do
      stories.each { |story| story.stub(:tasks).and_return([]) }

      sprint.should_receive(:stories).with(project).and_return(stories)
    end

    it 'contains the story id' do
      render

      stories.each do |story|
        rendered.should have_selector "#story_#{story.id}" do
          with_selector ".id", Regexp.new(story.id.to_s)
        end
      end
    end

    it 'has a title containing the story subject' do
      render

      stories.each do |story|
        rendered.should have_selector "#story_#{story.id}" do
          with_selector ".subject", story.subject
        end
      end
    end

    it 'contains the story status' do
      render

      stories.each do |story|
        rendered.should have_selector "#story_#{story.id}" do
          with_selector ".status", story.status.name
        end
      end
    end

    it 'contains the user it is assigned to' do
      render

      stories.each do |story|
        rendered.should have_selector "#story_#{story.id}" do
          with_selector ".assigned_to_id", assignee.name
        end
      end
    end
  end
end
