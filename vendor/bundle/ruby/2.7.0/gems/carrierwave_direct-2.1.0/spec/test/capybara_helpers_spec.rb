# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Test::CapybaraHelpers do
  class ExampleSpec
    include CarrierWaveDirect::Test::CapybaraHelpers
  end

  let(:subject) { ExampleSpec.new }
  let(:page) { double("Page").as_null_object }
  let(:selector) { double("Selector") }

  def stub_page
    allow(subject).to receive(:page).and_return(page)
  end

  def find_element_value(css, value, options = nil)
    if options
      allow(page).to receive(:find).with(css, options).and_return(selector)
    else
      allow(page).to receive(:find).with(css).and_return(selector)
    end
    allow(selector).to receive(:value).and_return(value)
  end

  describe "#attach_file_for_direct_upload" do
    context "'path/to/file.ext'" do
      it "should attach a file with the locator => 'file'" do
        expect(subject).to receive(:attach_file).with("file", "path/to/file.ext")
        subject.attach_file_for_direct_upload "path/to/file.ext"
      end
    end
  end

  describe "#upload_directly" do
    let(:uploader) { DirectUploader.new }

    def upload_directly(options = {})
      options[:button_locator] ||= ""
      button_locator = options.delete(:button_locator)
      subject.upload_directly(uploader, button_locator, options)
    end

    def stub_common
      stub_page
      find_element_value("input[name='success_action_redirect']", "http://example.com?custom_param=value", visible: false)
      allow(subject).to receive(:visit)
    end

    before do
      allow(subject).to receive(:click_button)
    end

    shared_examples_for "submitting the form" do
      let(:options) { {} }

      it "should submit the form" do
        expect(subject).to receive(:click_button).with("Upload!")
        upload_directly(options.merge(:button_locator => "Upload!"))
      end
    end

    shared_examples_for ":success => false" do
      let(:options) { { :success => false } }

      it "should not redirect" do
        expect(subject).to_not receive(:visit)
        upload_directly(options)
      end
    end

    context "passing no options" do
      before do
        stub_common
        allow(subject).to receive(:find_key).and_return("upload_dir/guid/$filename")
        allow(subject).to receive(:find_upload_path).and_return("path/to/file.ext")
      end

      it_should_behave_like "submitting the form"

      it "should redirect to the page's success_action_redirect url and preserve custom parameters" do
        expect(subject).to receive(:visit).with(/^http:\/\/example.com\?.*custom_param=value/)
        upload_directly
      end

      context "the redirect url's params" do
        it "should include the bucket name" do
          expect(subject).to receive(:visit).with(/bucket=/)
          upload_directly
        end

        it "should include an etag" do
          expect(subject).to receive(:visit).with(/etag=/)
          upload_directly
        end

        it "should include the key derived from the form" do
          expect(subject).to receive(:visit).with(/key=upload_dir%2Fguid%2Ffile.ext/)
          upload_directly
        end
      end
    end

    context "with options" do
      context ":redirect_key => 'some redirect key'" do
        before do
          stub_common
        end

        context "the redirect url's params" do
          it "should include the key from the :redirect_key option" do
            expect(subject).to receive(:visit).with(/key=some\+redirect\+key/)
            upload_directly(:redirect_key => "some redirect key")
          end
        end
      end

      context ":success => false" do
        let(:options) { { :success => false } }

        it_should_behave_like "submitting the form" do
          let(:options) { { :success => false } }
        end

        it_should_behave_like ":success => false"
      end

      context ":fail => true" do
        it_should_behave_like "submitting the form" do
          let(:options) { { :fail => true } }
        end

        it_should_behave_like ":success => false" do
          let(:options) { { :fail => true } }
        end
      end
    end
  end

  describe "#find_key" do
    before do
      stub_page
      find_element_value("input[name='key']", "key", visible: false)
    end

    it "should try to find the key on the page" do
      expect(subject.find_key).to eq "key"
    end
  end

  describe "#find_upload_path" do
    before do
      stub_page
      find_element_value("input[name='file']", "upload path", visible: false)
    end

    it "should try to find the upload path on the page" do
      expect(subject.find_upload_path).to eq "upload path"
    end
  end
end
