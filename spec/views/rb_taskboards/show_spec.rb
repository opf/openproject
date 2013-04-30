require File.dirname(__FILE__) + '/../../spec_helper'

describe 'rb_taskboards/show' do
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:role_allowed) { FactoryGirl.create(:role,
    :permissions => [:create_impediments, :create_tasks])
  }
  let(:role_forbidden) { FactoryGirl.create(:role) }
  #we need to create these as some view helpers access the database
  let(:statuses) { [FactoryGirl.create(:issue_status),
                    FactoryGirl.create(:issue_status),
                    FactoryGirl.create(:issue_status)] }

  let(:project) do
    project = FactoryGirl.create(:project)
    project.members = [FactoryGirl.create(:member, :principal => user1,:project => project,:roles => [role_allowed]),
                       FactoryGirl.create(:member, :principal => user2,:project => project,:roles => [role_forbidden])]
    project
  end

  let(:story_a) { FactoryGirl.build_stubbed(:story, :status => statuses[0])}
  let(:story_b) { FactoryGirl.build_stubbed(:story, :status => statuses[1])}
  let(:story_c) { FactoryGirl.build_stubbed(:story, :status => statuses[2])}
  let(:stories) { [story_a, story_b, story_c] }
  let(:sprint)   { FactoryGirl.build_stubbed(:sprint) }
  #let(:assignee) { user }

  before :each do
    view.extend RbCommonHelper
    view.extend TaskboardsHelper

    assign(:project, project)
    assign(:sprint, sprint)
    assign(:statuses, statuses)

    stories.each { |story| story.stub(:tasks).and_return([]) }
    sprint.should_receive(:stories).with(project).and_return(stories)
  end

  describe 'story blocks' do

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

  describe 'create buttons' do

    it 'renders clickable + buttons for all stories with the right permissions' do
      User.current = user1

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          td.should have_content '+'
          td.should have_css '.clickable'
        end
      end
    end

    it 'does not render a clickable + buttons for all stories without the right permissions' do
      User.current = user2

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          td.should_not have_content '+'
          td.should_not have_css '.clickable'
        end
      end
    end

    it 'renders clickable + buttons for impediments with the right permissions' do
      User.current = user1

      render

      stories.each do |story|
        assert_select '#impediments td.add_new' do |td|
          td.should have_content '+'
          td.should have_css '.clickable'
        end
      end
    end

    it 'does not render a clickable + buttons for impediments without the right permissions' do
      User.current = user2

      render

      stories.each do |story|
        assert_select '#impediments td.add_new' do |td|
          td.should_not have_content '+'
          td.should_not have_css '.clickable'
        end
      end
    end
  end
end
