require File.dirname(__FILE__) + '/../../spec_helper'

describe 'wiki/new.html.erb' do
  let(:project) { stub_model(Project) }
  let(:wiki)    { stub_model(Wiki) }
  let(:page)    { stub_model(WikiPage) }
  let(:content) { stub_model(WikiContent) }

  before do
    assigns[:project] = project
    assigns[:wiki]    = wiki
    assigns[:page]    = page
    assigns[:content] = content
  end

  it 'renders a form which POSTs to wiki_create_path' do
    project.identifier = 'my_project'

    render
    response.should have_tag('form[action=?][method=?]', wiki_create_path(:project_id => project), 'post')
  end

  it 'contains an input element for title' do
    page.title = 'Boogie'

    render
    response.should have_tag('input[name=?][value=?]', 'page[title]', 'Boogie')
  end

  it 'contains an input element for parent page' do
    page.parent_id = 123

    render
    response.should have_tag('input[name=?][value=?][type=hidden]', 'page[parent_id]', 123)
  end
end
