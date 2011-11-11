require File.dirname(__FILE__) + '/../spec_helper'

describe MyProjectsOverview do
  before do
    @enabled_module_names = %w[activity issue_tracking news wiki]
    Factory.create(:project, :enabled_module_names => @enabled_module_names)
    @project = Project.find(:first)
    @overview = MyProjectsOverview.create(:project_id => @project.id)
  end

  it 'creates a new custom element' do
    @overview.new_custom_element.should_not be_nil
  end

  it "creates a new custom element as [idx, title, text]" do
    ce = @overview.new_custom_element
    ce[0].should == "a"
    ce[1].should be_kind_of String
    ce[2].should =~ /^h2\./
  end

  it "can save a custom element" do
    @overview.hidden << @overview.new_custom_element
    ce = @overview.custom_elements.last
    @overview.save_custom_element(ce[0], "Title", "Content").should be true
    ce[1].should == "Title"
    ce[2].should == "Content"
  end

  it "should always show attachments" do
    @overview.attachments_visible?(nil).should be true
  end
end
