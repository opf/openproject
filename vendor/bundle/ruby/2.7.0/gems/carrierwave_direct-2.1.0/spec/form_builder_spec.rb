# encoding: utf-8

require 'spec_helper'
require 'erb'

class CarrierWaveDirect::FormBuilder
  attr_accessor :template, :object

  public :content_choices_options
end

shared_examples_for 'hidden values form' do
  hidden_fields = [
                    :key,
                    {:credential => "X-Amz-Credential"},
                    {:algorithm => "X-Amz-Algorithm"},
                    {:date => "X-Amz-Date"},
                    {:signature => "X-Amz-Signature"},
                    :acl,
                    :success_action_redirect,
                    :policy
                  ]

  hidden_fields.each do |input|
    if input.is_a?(Hash)
      key = input.keys.first
      name = input[key]
    else
      key = name = input
    end

    it "should have a hidden field for '#{name}'" do
      allow(direct_uploader.send(:signing_policy)).to receive(key).and_return(key.to_s)
      allow(direct_uploader).to receive(key).and_return(key.to_s)
      expect(subject).to have_input(
        :direct_uploader,
        key,
        :type => :hidden,
        :name => name,
        :value => direct_uploader.send(key),
        :required => false
      )
    end
  end
end

describe CarrierWaveDirect::FormBuilder do
  include FormBuilderHelpers

  describe "#file_field" do

    def form_with_default_file_field
      form {|f| f.file_field :video }
    end

    def form_with_file_field_and_no_redirect
      allow(@direct_uploader.class).to receive(:use_action_status).and_return(true)

      form do |f|
        f.file_field :video
      end
    end

    default_hidden_fields = [
                      :key,
                      {:credential => "X-Amz-Credential"},
                      {:algorithm => "X-Amz-Algorithm"},
                      {:date => "X-Amz-Date"},
                      {:signature => "X-Amz-Signature"},
                      :acl,
                      :success_action_redirect,
                      :policy,
                    ]
    status_hidden_fields = [
                      :key,
                      {:credential => "X-Amz-Credential"},
                      {:algorithm => "X-Amz-Algorithm"},
                      {:date => "X-Amz-Date"},
                      {:signature => "X-Amz-Signature"},
                      :acl,
                      :success_action_status,
                      :policy,
                    ]

    # http://aws.amazon.com/articles/1434?_encoding=UTF8
    context "form" do
      subject { form_with_default_file_field }
      it_should_behave_like 'hidden values form'

      default_hidden_fields.each do |input|
        if input.is_a?(Hash)
          key = input.keys.first
          name = input[key]
        else
          key = name = input
        end

        it "should have a hidden field for '#{name}'" do
          allow(direct_uploader.send(:signing_policy)).to receive(key).and_return(key.to_s)
          allow(direct_uploader).to receive(key).and_return(key.to_s)
          expect(subject).to have_input(
            :direct_uploader,
            key,
            :type => :hidden,
            :name => name,
            :value => direct_uploader.send(key),
            :required => false
          )
        end
      end

      status_hidden_fields.each do |input|
        if input.is_a?(Hash)
          key = input.keys.first
          name = input[key]
        else
          key = name = input
        end

        it "should have a hidden field for '#{name}'" do
          allow(direct_uploader.send(:signing_policy)).to receive(key).and_return(key.to_s)
          allow(direct_uploader).to receive(key).and_return(key.to_s)
          expect(form_with_file_field_and_no_redirect).to have_input(
            :direct_uploader,
            key,
            :type => :hidden,
            :name => name,
            :value => direct_uploader.send(key),
            :required => false
          )
        end
      end

      it "should have an input for a file to upload" do
        expect(subject).to have_input(
          :direct_uploader,
          :video,
          :type => :file,
          :name => :file,
          :required => false
        )
      end
    end
  end

  describe "#content_type_select" do
    context "form" do
      subject do
        form do |f|
          f.content_type_select
        end
      end

      before do
        allow(direct_uploader.class).to receive(:will_include_content_type).and_return(true)
      end

      it 'should select the default content type' do
        allow(direct_uploader).to receive(:content_type).and_return('video/mp4')
        expect(subject).to have_content_type 'video/mp4', true
      end

      it 'should include the default content types' do
        allow(direct_uploader).to receive(:content_types).and_return(['text/foo','text/bar'])
        expect(subject).to have_content_type 'text/foo', false
        expect(subject).to have_content_type 'text/bar', false
      end

      it 'should select the passed in content type' do
        dom = form {|f| f.content_type_select nil, 'video/mp4'}
        expect(dom).to have_content_type 'video/mp4', true
      end

      it 'should include most content types' do
        %w(application/atom+xml application/ecmascript application/json application/javascript application/octet-stream application/ogg application/pdf application/postscript application/rss+xml application/font-woff application/xhtml+xml application/xml application/xml-dtd application/zip application/gzip audio/basic audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg image/png image/svg+xml image/tiff text/cmd text/css text/csv text/html text/javascript text/plain text/vcard text/xml video/mpeg video/mp4 video/ogg video/quicktime video/webm video/x-matroska video/x-ms-wmv video/x-flv).each do |type|
          expect(subject).to have_content_type type
        end
      end
    end
  end

  describe "#content_type_label" do
    context "form" do
      subject do
        form do |f|
          f.content_type_label
        end
      end

    end
  end

  describe 'full form' do
    let(:dom) do
      form do |f|
        f.content_type_label <<
        f.content_type_select <<
        f.file_field(:video)
      end
    end

    before do
      allow(direct_uploader).to receive('key').and_return('foo')
      allow(direct_uploader.class).to receive(:will_include_content_type).and_return(true)
    end

    it 'should only include the hidden values once' do
      expect(dom).to have_input(
                   :direct_uploader,
                   'key',
                   :type => :hidden,
                   :name => 'key',
                   :value => 'foo',
                   :required => false,
                   :count => 1
                 )
    end

    it 'should include Content-Type twice' do
      expect(dom).to have_input(
                   :direct_uploader,
                   :content_type,
                   :type => :hidden,
                   :name => 'Content-Type',
                   :value => 'binary/octet-stream',
                   :required => false,
                   :count => 1
                 )

      expect(dom).to have_selector :xpath, './/select[@name="Content-Type"]', :count => 1
    end
  end
end
