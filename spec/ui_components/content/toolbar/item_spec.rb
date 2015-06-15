require 'spec_helper'

describe UiComponents::Content::Toolbar::Item do
  let(:item) { described_class.new(attributes).render! }
  let(:attributes) { { element: element } }
  let(:element) { nil }

  it 'should render an entry for the toolbar' do
    expect(item).to be_html_eql %{
      <li class="toolbar-item" role="menuitem"></li>
    }
  end

  describe 'holding other items' do
    let(:element) { UiComponents::Content::Button.new text: 'Foo', icon: :time }

    it 'should embed other elements' do
      expect(item).to be_html_eql %{
        <li class="toolbar-item" role="menuitem">
          <a class="button" role="button">
            <i class="button--icon icon-time"></i>
            <span class="button--text">Foo</span>
          </a>
        </li>
      }
    end
  end
end
