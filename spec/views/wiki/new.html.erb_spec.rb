require 'spec_helper'

describe 'wiki/new' do
  let(:project) { stub_model(Project) }
  let(:wiki)    { stub_model(Wiki) }
  let(:page)    { stub_model(WikiPage) }
  let(:content) { stub_model(WikiContent) }

  before do
    assign(:project, project)
    assign(:wiki,    wiki)
    assign(:page,    page)
    assign(:content, content)
  end

  it 'renders a form which POSTs to wiki_create_path' do
    project.identifier = 'my_project'
    render
    assert_select "form", :action => wiki_create_path(:project_id => project), :method => 'post'
  end

  it 'contains an input element for title' do
    page.title = 'Boogie'

    render
    assert_select "input", :name => 'page[title]', :value => 'Boogie'
  end

  it 'contains an input element for parent page' do
    page.parent_id = 123

    render
    assert_select "input", :name => 'page[parent_id]', :value => '123', :type => 'hidden'
  end
end
