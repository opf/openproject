require File.dirname(__FILE__) + '/../../spec_helper'

describe 'rb_taskboards/show' do
  let(:project)  { stub_model(Project) }
  let(:sprint)   { stub_model(Sprint) }
  let(:statuses) { [stub_model(IssueStatus, :name => 'Open'),
                    stub_model(IssueStatus, :name => 'In Progress'),
                    stub_model(IssueStatus, :name => 'Closed')] }

  let(:assignee) { stub_model(User, :firstname => 'Karl', :lastname => 'Gustav') }

  before :each do
    template.extend RbCommonHelper
    template.extend TaskboardsHelper

    assigns[:project]  = project
    assigns[:sprint]   = sprint
    assigns[:statuses] = statuses
  end

  describe 'story blocks' do
    let(:story_a) { stub_model(Story, :id => 1001, :subject => 'Story A', :status => statuses[0], :assigned_to => assignee) }
    let(:story_b) { stub_model(Story, :id => 1002, :subject => 'Story B', :status => statuses[1], :assigned_to => assignee) }
    let(:story_c) { stub_model(Story, :id => 1003, :subject => 'Story C', :status => statuses[2], :assigned_to => assignee) }
    let(:stories) { [story_a, story_b, story_c] }

    before do
      stories.each { |story| story.stub(:tasks).and_return([]) }

      sprint.should_receive(:stories).with(project).and_return(stories)
    end

    it 'contains the story id' do
      render

      stories.each do |story|
        template.should have_tag "#story_#{story.id}" do
          with_tag ".id", Regexp.new(story.id.to_s)
        end
      end
    end

    it 'has a title containing the story subject' do
      render

      stories.each do |story|
        template.should have_tag "#story_#{story.id}" do
          with_tag ".subject", story.subject
        end
      end
    end

    it 'contains the story status' do
      render

      stories.each do |story|
        template.should have_tag "#story_#{story.id}" do
          with_tag ".status", story.status.name
        end
      end
    end

    it 'contains the user it is assigned to' do
      render

      stories.each do |story|
        template.should have_tag "#story_#{story.id}" do
          with_tag ".assigned_to_id", assignee.name
        end
      end
    end
  end
end
