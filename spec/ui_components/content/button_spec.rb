require 'spec_helper'

describe UiComponents::Content::Button do
  let(:button) { described_class.new(attributes).render! }

  describe 'w/o any options' do
    let(:attributes) { { text: 'Button' } }
    it 'should render to a normal button' do
      expect(button).to be_html_eql %{
        <a class="button" role="button">
          <span class="button--text">Button</span>
        </a>
      }
    end
  end

  describe 'w/ icon' do
    let(:attributes) { { icon: :time } }
    it 'should be able to render an icon' do
      expect(button).to be_html_eql %{
        <a class="button" role="button">
          <i class="button--icon icon-time"></i>
          <span class="button--text"></span>
        </a>
      }
    end
  end

  describe 'w/ accesskey' do
    let(:attributes) { { accesskey: 'more_menu' } }

    it 'should render an access key via OpenProject:Accesskeys' do
      expect(button).to be_html_eql %{
        <a class="button" role="button" accesskey="7">
          <span class="button--text"></span>
        </a>
      }
    end
  end

  describe 'w/ highlight' do
    let(:attributes) { { highlight: highlight, text: text } }

    describe 'alt' do
      let(:highlight) { :alt }
      let(:text) { 'Green button' }
      it 'should be able to render alternative highlight' do
        expect(button).to be_html_eql %{
          <a class="button -alt-highlight" role="button">
            <span class="button--text">Green button</span>
          </a>
        }
      end
    end

    describe 'default' do
      let(:highlight) { :default }
      let(:text) { 'Blue button' }
      it 'should be able to render default highlight' do
        expect(button).to be_html_eql %{
          <a class="button -highlight" role="button">
            <span class="button--text">Blue button</span>
          </a>
        }
      end
    end
  end

  describe 'tag attributes' do
    {
      href: {
        input: 'https://openproject.com',
        expected: 'href="https://openproject.com"'
      },
      hreflang: {
        input: 'de',
        expected: 'hreflang="de"'
      },
      media: {
        input: 'print and (resolution:300dpi)',
        expected: 'media="print and (resolution:300dpi)"'
      },
      rel: {
        input: 'nofollow',
        expected: 'rel="nofollow"'
      },
      type: {
        input: 'text/html',
        expected: 'type="text/html"'
      },
      target: {
        input: '_blank',
        expected: 'target="_blank"'
      }
    }.each_pair do |field, setup|
      describe "settable #{field}" do
        let(:attributes) { { field => setup[:input], text: 'Blue button' } }
        it 'should be rendered' do
          expect(button).to be_html_eql %{
            <a class="button" role="button" #{setup[:expected]}>
              <span class="button--text">Blue button</span>
            </a>
          }
        end
      end
    end
  end
end
