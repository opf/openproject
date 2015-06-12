require 'spec_helper'

describe UiComponents::Content::Toolbar::Submenu do
  let(:submenu) { described_class.new(attributes).render! }
  let(:attributes) { { icon: icon, text: text, items: items, last: last } }
  let(:icon) { :gear }
  let(:text) { 'Submenu' }
  let(:items) { [] }

  describe 'default' do
    let(:last) { false }

    it 'should render an empty submenu' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu"></ul>
        </li>
      }
    end
  end

  describe 'last property' do
    let(:last) { true }

    it 'should render a last modifier' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu -last"></ul>
        </li>
      }
    end
  end

  describe 'w/ items' do
    let(:items) {
      [UiComponents::Content::Toolbar::SubmenuItem.new(icon: :gear, text: 'foo', href: '#bar')] * 2
    }
    let(:last) { false }

    it 'should render the children of the menu' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu">
            <li class="toolbar-item">
              <a href="#bar">
                <i class="button--icon icon-gear"></i>
                <span class="button--text">foo</span>
              </a>
            </li>
            <li class="toolbar-item">
              <a href="#bar">
                <i class="button--icon icon-gear"></i>
                <span class="button--text">foo</span>
              </a>
            </li>
          </ul>
        </li>
      }
    end
  end
end
