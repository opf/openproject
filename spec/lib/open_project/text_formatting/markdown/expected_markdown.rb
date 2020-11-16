shared_context 'expected markdown modules' do
  include OpenProject::TextFormatting
  include ERB::Util
  include WorkPackagesHelper # soft-dependency
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end
end

shared_examples_for 'format_text produces' do
  subject { format_text(raw) }

  it 'produces the expected output' do
    is_expected
      .to be_html_eql(expected)
  end
end
