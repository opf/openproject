require 'spec_helper'

describe UiComponents::Content::Header do
  let(:title) { 'Red Hot Chili Peppers' }
  let(:scrollable) { false }
  let(:subtitle) { false }
  let(:toolbar) { nil }
  let(:attributes) {
    { title: title, subtitle: subtitle, scrollable: scrollable, toolbar: toolbar }
  }
  let(:header) { described_class.new(attributes).render! }

  describe 'w/o toolbar' do
    it 'should render to a header with an empty toolbar included' do
      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2 title="Red Hot Chili Peppers">Red Hot Chili Peppers</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end
  end

  describe 'w/ toolbar' do
    let(:items) { [UiComponents::Content::Toolbar::Item.new] * 3 }
    let(:toolbar) { UiComponents::Content::Toolbar.new items: items }

    it 'should draw a header w/ a toolbar containing items' do
      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2 title="Red Hot Chili Peppers">Red Hot Chili Peppers</h2>
            </div>
            <ul class="toolbar-items">
              <li class="toolbar-item"></li>
              <li class="toolbar-item"></li>
              <li class="toolbar-item"></li>
            </ul>
          </div>
        </div>
      }
    end

    describe 'w/ submenu' do
      let(:submenu_items) {
        [
          UiComponents::Content::Toolbar::SubmenuItem.new(href: '#', text: 'foo', icon: :stop),
          UiComponents::Content::Toolbar::SubmenuItem.new(divider: true),
          UiComponents::Content::Toolbar::SubmenuItem.new(href: '#', text: 'bar', icon: :hammer),
          UiComponents::Content::Toolbar::SubmenuItem.new(href: '#', text: 'baz', icon: :time),
        ]
      }
      let(:submenu) {
        UiComponents::Content::Toolbar::Submenu.new items: submenu_items, last: true, text: 'Foo'
      }
      let(:button) {
        UiComponents::Content::Button.new text: 'MC', href: '#Hammer', icon: :glasses
      }
      let(:items) {
        [UiComponents::Content::Toolbar::Item.new(element: button)] * 2 + [submenu]
      }
      let(:scrollable) { true }

      it 'should render correctly' do
        expect(header).to be_html_eql %{
          <div class="toolbar-container">
            <div class="toolbar -scrollable">
              <div class="title-container">
                <h2 title="Red Hot Chili Peppers">Red Hot Chili Peppers</h2>
              </div>
              <ul class="toolbar-items">
                <li class="toolbar-item">
                  <a href="#Hammer" class="button">
                    <i class="button--icon icon-glasses"></i>
                    <span class="button--text">MC</span>
                  </a>
                </li>
                <li class="toolbar-item">
                  <a href="#Hammer" class="button">
                    <i class="button--icon icon-glasses"></i>
                    <span class="button--text">MC</span>
                  </a>
                </li>
                <li class="toolbar-item -with-submenu">
                  <a href="#" class="button">
                    <span class="button--text">MC</span>
                    <i class="button--dropdown-indicator"></i>
                  </a>
                  <ul class="toolbar-submenu -last">
                    <li class="toolbar-item">
                      <a href="#">
                        <i class="button--icon icon-stop"></i>
                        <span class="button--text">foo</span>
                      </a>
                    </li>
                    <li class="toolbar-item -divider"></li>
                    <li class="toolbar-item">
                      <a href="#">
                        <i class="button--icon icon-hammer"></i>
                        <span class="button--text">bar</span>
                      </a>
                    </li>
                    <li class="toolbar-item">
                      <a href="#">
                        <i class="button--icon icon-time"></i>
                        <span class="button--text">baz</span>
                      </a>
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
          </div>
        }
      end
    end
  end

  describe 'scrollable attribute' do
    let(:scrollable) { true }

    it 'should add a scrollable modificator' do
      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar -scrollable">
            <div class="title-container">
              <h2 title="Red Hot Chili Peppers">Red Hot Chili Peppers</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end
  end

  describe 'subtitle attribute' do
    let(:subtitle) { 'Stadium arcadium' }

    it 'should add a subtitle paragraph' do
      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2 title="Red Hot Chili Peppers">Red Hot Chili Peppers</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
          <p class="subtitle">Stadium arcadium</p>
        </div>
      }
    end
  end
end
