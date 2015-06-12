require 'spec_helper'

describe UiComponents::Content::Toolbar::SubmenuItem do
  let(:submenu_item) { described_class.new(attributes).render! }

  describe 'using it as a link' do
    let(:attributes) { { href: 'http://foo.bar.com', class: 'my very own classes', icon: icon } }

    describe 'w/ an icon' do
      let(:icon) { :time }
      it "should render a menu item with an icon" do
        expect(submenu_item).to be_html_eql %{
          <li class="toolbar-item">
            <a href="http://foo.bar.com" class="my very own classes">
              <i class="button--icon icon-time"></i>
              <span class="button--text"></span>
            </a>
          </li>
        }
      end
    end

    describe 'w/o an icon' do
      let(:icon) { false }
      it "should render a modifier class" do
        expect(submenu_item).to be_html_eql %{
          <li class="toolbar-item no-icon">
            <a href="http://foo.bar.com" class="my very own classes">
              <span class="button--text"></span>
            </a>
          </li>
        }
      end
    end
  end

  describe 'using it as a divider' do
    let(:attributes) { { divider: true } }

    it 'should render as a menu divider' do
      expect(submenu_item).to be_html_eql %{
        <li class="toolbar-item -divider"></li>
      }
    end
  end

end
