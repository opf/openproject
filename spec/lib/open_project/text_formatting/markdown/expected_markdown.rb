RSpec.shared_context "expected markdown modules" do
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

RSpec.shared_examples_for "format_text produces" do
  let(:passed_options) { defined?(options) ? options : {} }
  subject { format_text(raw, passed_options) }

  it "the expected output" do
    expect(subject)
      .to be_html_eql(expected)
  end
end
