require File.dirname(__FILE__) + '/../../spec_helper'

describe 'rb_taskboards/show' do
  let(:project)  { stub_model(Project) }
  let(:sprint)   { stub_model(Sprint) }
  let(:statuses) { [stub_model(IssueStatus, :name => 'Open'),
                    stub_model(IssueStatus, :name => 'In Progress'),
                    stub_model(IssueStatus, :name => 'Closed')] }

  before :each do
    template.extend RbCommonHelper
    template.extend TaskboardsHelper

    assigns[:project]  = project
    assigns[:sprint]   = sprint
    assigns[:statuses] = statuses


  end

  describe 'story blocks' do
    it 'contains the story id' do
      render
    end

    it 'contains the story title'
    it 'contains the story status'
    it 'contains the user it is assigned to'
  end
end
