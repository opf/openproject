require 'spec_helper'

describe UiComponents::Content::Toolbar do
  let(:toolbar) { described_class.new(attributes).render! }
  context 'when empty' do
    let(:attributes) { {} }
    it 'should render to an empty toolbar' do
      expect(toolbar).to be_html_eql %{
        <ul class="toolbar-items"></ul>
      }
    end
  end
end
