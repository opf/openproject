require 'spec_helper'

describe UiComponents::Element do
  let(:element) { described_class.new(attributes).render! }

  describe 'w/o attributes' do
    let(:attributes) { {} }

    it 'should render with a default strategy' do
      expect(element).to be_html_eql %{
        <div></div>
      }
    end
  end

  describe 'w/ attributes' do
    {
      accesskey: {
        input: :edit,
        expected: 'accesskey="3"'
      },
      contenteditable: {
        input: true,
        expected: 'contenteditable="true"'
      },
      contextmenu: {
        input: '#menu',
        expected: 'contextmenu="#menu"'
      },
      data: {
        input: { url: 'https://openproject.com' },
        expected: 'data-url="https://openproject.com"'
      },
      dir: {
        input: :ltr,
        expected: 'dir="ltr"'
      },
      draggable: {
        input: false,
        expected: 'draggable="false"'
      },
      dropzone: {
        input: :copy,
        expected: 'dropzone="copy"'
      },
      id: {
        input: 'foobar',
        expected: 'id="foobar"'
      },
      lang: {
        input: :de,
        expected: 'lang="de"'
      },
      spellcheck: {
        input: true,
        expected: 'spellcheck="true"'
      },
      style: {
        input: 'display:none;',
        expected: 'style="display:none;"'
      },
      tabindex: {
        input: 12,
        expected: 'tabindex="12"'
      },
      title: {
        input: 'Baz',
        expected: 'title="Baz"'
      },
      translate: {
        input: true,
        expected: 'translate="yes"'
      },
      class: {
        input: 'foo bar baz',
        expected: 'class="foo bar baz"'
      }

    }.each_pair do |field, setup|
      describe "w/ the `#{field}` attribute" do
        let(:attributes) { { field => setup[:input] } }
        it 'should render the value for the attribute' do
          expect(element).to be_html_eql %{
            <div #{setup[:expected]}></div>
          }
        end
      end
    end
  end
end
