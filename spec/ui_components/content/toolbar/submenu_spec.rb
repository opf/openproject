require 'spec_helper'

describe UiComponents::Content::Toolbar::Submenu do
  let(:submenu) { described_class.new(attributes).render! }
  let(:attributes) { { icon: icon, title: title, items: items, last: last, accesskey: accesskey } }
  let(:icon) { :gear }
  let(:title) { 'Submenu' }
  let(:items) { [] }
  let(:accesskey) { nil }
  let(:last) { false }

  describe 'default' do
    it 'should render an empty submenu' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu" aria-haspopup="true" role="menuitem" title="Submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu" aria-hidden="true" role="menu"></ul>
        </li>
      }
    end
  end

  describe 'last property' do
    let(:last) { true }

    it 'should render a last modifier' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu" aria-haspopup="true" role="menuitem" title="Submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu -last" aria-hidden="true" role="menu"></ul>
        </li>
      }
    end
  end

  describe 'w/ items' do
    let(:items) {
      [UiComponents::Content::Toolbar::SubmenuItem.new(icon: :gear, text: 'foo', href: '#bar')] * 2
    }

    it 'should render the children of the menu' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu" aria-haspopup="true" role="menuitem" title="Submenu">
          <a class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu" aria-hidden="true" role="menu">
            <li class="toolbar-item" role="menuitem">
              <a href="#bar">
                <i class="button--icon icon-gear"></i>
                <span class="button--text">foo</span>
              </a>
            </li>
            <li class="toolbar-item" role="menuitem">
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

  describe 'w/ accesskey' do
    let(:accesskey) { :more_menu }

    it 'should add the accesskey to the list item\'s link' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu" aria-haspopup="true" role="menuitem" title="Submenu">
          <a accesskey="7" class="button" href="#">
            <i class="button--icon icon-gear"></i>
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu" aria-hidden="true" role="menu"></ul>
        </li>
      }
    end
  end

  describe 'w/o icon' do
    let(:icon) { false }

    it 'should add the accesskey to the list item\'s link' do
      expect(submenu).to be_html_eql %{
        <li class="toolbar-item -with-submenu" aria-haspopup="true" role="menuitem" title="Submenu">
          <a class="button" href="#">
            <span class="button--text">Submenu</span>
            <i class="button--dropdown-indicator"></i>
          </a>
          <ul class="toolbar-submenu" aria-hidden="true" role="menu"></ul>
        </li>
      }
    end
  end
end
