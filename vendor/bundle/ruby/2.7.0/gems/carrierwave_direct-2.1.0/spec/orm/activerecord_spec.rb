# encoding: utf-8

require 'spec_helper'
require 'carrierwave/orm/activerecord'
require 'carrierwave_direct/orm/activerecord'

describe CarrierWaveDirect::ActiveRecord do
  dbconfig = {
    :adapter => 'sqlite3',
    :database => ':memory:'
  }
  if ActiveRecord::VERSION::MAJOR >= 5
    migration_class = ::ActiveRecord::Migration[5.0]
  else
    migration_class = ::ActiveRecord::Migration
  end
  class TestMigration < migration_class
    def self.up
      create_table :parties, :force => true do |t|
        t.column :video, :string
      end

      create_table :dances, :force => true do |t|
        t.column :location, :string
      end
      create_table :resources, :force => true do |t|
        t.column :file, :string
      end
    end

    def self.down
      drop_table :parties
      drop_table :dances
    end
  end

  class Party < ActiveRecord::Base
    mount_uploader :video, DirectUploader
  end

  class Dance < ActiveRecord::Base
  end

  class Resource < ActiveRecord::Base
    mount_uploader :file, DirectUploader
  end

  ActiveRecord::Base.establish_connection(dbconfig)

  # turn off migration output
  ActiveRecord::Migration.verbose = false

  before(:all) { TestMigration.up }
  after(:all) { TestMigration.down }
  after { Party.delete_all }

  describe "class Party < ActiveRecord::Base; mount_uploader :video, DirectUploader; end" do
    $arclass = 0
    include UploaderHelpers
    include ModelHelpers

    let(:party_class) do
      Class.new(Party)
    end

    let(:subject) do
      party = party_class.new
    end

    def mount_uploader
      party_class.mount_uploader :video, DirectUploader
    end

    before do
      # see https://github.com/jnicklas/carrierwave/blob/master/spec/orm/activerecord_spec.rb
      $arclass += 1
      Object.const_set("Party#{$arclass}", party_class)
      party_class.table_name = "parties"
    end

    shared_examples_for "an invalid filename" do
      it "should not be valid on create" do
        expect(subject).to_not be_valid
      end

      it "should be valid on update" do
        subject.save(:validate => false)
        expect(subject).to be_valid
      end

      it "should use i18n for the error messages" do
        subject.valid?
        expect(subject.errors[:video]).to eq [
          I18n.t("errors.messages.carrierwave_direct_filename_invalid") +
          I18n.t("errors.messages.carrierwave_direct_allowed_extensions", :extensions => %w{avi mp4}.to_sentence)
        ]
      end
    end

    shared_examples_for "a remote net url i18n error message" do
      it "should use i18n for the error messages" do
        subject.valid?

        messages = I18n.t("errors.messages.carrierwave_direct_filename_invalid")

        if i18n_options
          if i18n_options[:extension_whitelist]
            extensions = i18n_options[:extension_whitelist].to_sentence
            messages += I18n.t("errors.messages.carrierwave_direct_allowed_extensions", :extensions => extensions)
          end

           if i18n_options[:url_scheme_white_list]
            schemes = i18n_options[:url_scheme_white_list].to_sentence
            messages += I18n.t("errors.messages.carrierwave_direct_allowed_schemes", :schemes => schemes)
          end
        end

        expect(subject.errors[:remote_video_net_url]).to eq [ messages ]
      end
    end

    shared_examples_for "without an upload" do
      before do
        subject.remote_video_net_url = remote_video_net_url
        subject.video_key = upload_path
      end

      it "should not be valid on create" do
        subject.should_not be_valid
      end

      it "should use i18n for the file upload error message" do
        subject.valid?
        subject.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_upload_missing")]
      end

      it "should use i18n for the remote net url error message" do
        subject.valid?
        subject.errors[:remote_video_net_url].should == [I18n.t("errors.messages.blank")]
      end

      it "should be valid on update" do
        subject.save(:validate => false)
        subject.should be_valid
      end
    end

    shared_examples_for "a blank or empty attachment" do
      it "should not be valid" do
        subject.should_not be_valid
      end

      context "on update" do
        it "should not be valid" do
          subject.save(:validate => false)
          subject.should_not be_valid
        end
      end

      it "should use i18n for the error messages" do
        subject.valid?
        subject.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_attachment_missing")]
      end
    end

    describe ".validates_filename_uniqueness_of" do
      it "should be turned on by default" do
        party_class.should_receive(:validates_filename_uniqueness_of).with(:video, on: :create)
        mount_uploader
      end

      context "mount_on: option is used" do
        let(:dance) { Dance.new }

        before { Dance.mount_uploader(:non_existing_column, DirectUploader, mount_on: :location)    }
        before { dance.non_existing_column_key = sample_key}

        it "uses the column it's mounted on for checking uniqueness" do
          expect { dance.valid? }.to_not raise_error
        end
      end

      context "another Party with a duplicate video filename" do
        before do
          subject.video.key = sample_key
          subject.save
        end

        let(:another_party) do
          another_party = party_class.new
          another_party.video.key = subject.video.key
          another_party
        end

        it "should not be valid" do
          another_party.should_not be_valid
        end

        it "should use I18n for the error messages" do
          another_party.valid?
          another_party.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_filename_taken")]
        end
      end

      context "is turned off in the configuration" do
        before do
          DirectUploader.validate_unique_filename = false
        end

        it "should not validate the filename uniqueness" do
          party_class.should_not_receive(:validates_filename_uniqueness_of)
          mount_uploader
        end
      end
    end

    describe ".validates_filename_format_of" do
      it "should be turned on by default" do
        party_class.should_receive(:validates_filename_format_of).with(:video, on: :create)
        mount_uploader
      end

      context "where the file upload is" do
        context "nil" do
          before do
            subject.video_key = nil
          end

          it "should be valid" do
            subject.should be_valid
          end
        end

        context "blank" do
          before do
            subject.video_key = ""
          end

          it "should be valid" do
            subject.should be_valid
          end
        end
      end

      context "where the uploader has an extension white list" do
        before do
          subject.video.stub(:extension_whitelist).and_return(%w{avi mp4})
        end

        context "and the uploaded file's extension is included in the list" do
          before do
            subject.video_key = sample_key(:extension => "avi")
          end

          it "should be valid" do
            subject.should be_valid
          end
        end

        context "but uploaded file's extension is not included in the list" do
          before do
            subject.video_key = sample_key(:extension => "mp3")
          end

          it_should_behave_like "an invalid filename"

          it "should include the white listed extensions in the error message" do
            subject.valid?
            subject.errors[:video].first.should include("avi and mp4")
          end
        end

        context "and the video's key does not contain a guid" do
          before do
            subject.video.key = sample_key(:valid => false)
          end

          it_should_behave_like "an invalid filename"
        end
      end

      context "is turned off in the configuration" do
        before do
          DirectUploader.validate_filename_format = false
        end

        it "should not validate the filename format" do
          party_class.should_not_receive(:validates_filename_format_of)
          mount_uploader
        end
      end
    end

    describe ".validates_remote_net_url_format_of" do
      it "should be turned on by default" do
        party_class.should_receive(:validates_remote_net_url_format_of).with(:video, on: :create)
        mount_uploader
      end

      context "with an invalid remote image net url" do

        context "on create" do
          context "where the uploader has an extension white list" do
            before do
              subject.video.stub(:extension_whitelist).and_return(%w{avi mp4})
            end

            context "and the url's extension is included in the list" do
              before do
                subject.remote_video_net_url = "http://example.com/some_video.mp4"
              end

              it "should be valid" do
                subject.should be_valid
              end
            end

            context "but the url's extension is not included in the list" do
              before do
                subject.remote_video_net_url = "http://example.com/some_video.mp3"
              end

              it "should not be valid" do
                subject.should_not be_valid
              end

              it_should_behave_like "a remote net url i18n error message" do
                let(:i18n_options) { {:extension_whitelist => %w{avi mp4} } }
              end

              it "should include the white listed extensions in the error message" do
                subject.valid?
                subject.errors[:remote_video_net_url].first.should include("avi and mp4")
              end
            end
          end

          context "where the url is invalid" do
            before do
              subject.remote_video_net_url = "http$://example.com/some_video.mp4"
            end

            it "should not be valid" do
              subject.should_not be_valid
            end

            it_should_behave_like "a remote net url i18n error message" do
              let(:i18n_options) { nil }
            end
          end

          context "where the url is" do
            context "nil" do
              before do
                subject.remote_video_net_url = nil
              end

              it "should be valid" do
                subject.should be_valid
              end
            end

            context "blank" do
              before do
                subject.remote_video_net_url = ""
              end

              it "should be valid" do
                subject.should be_valid
              end
            end
          end

          context "where the uploader specifies valid url schemes" do
            before do
              subject.video.stub(:url_scheme_white_list).and_return(%w{http https})
            end

            context "and the url's scheme is included in the list" do
              before do
                subject.remote_video_net_url = "https://example.com/some_video.mp3"
              end

              it "should be valid" do
                subject.should be_valid
              end
            end

            context "but the url's scheme is not included in the list" do
              before do
                subject.remote_video_net_url = "ftp://example.com/some_video.mp3"
              end

              it "should not be valid" do
                subject.should_not be_valid
              end

              it_should_behave_like "a remote net url i18n error message" do
                let(:i18n_options) { {:url_scheme_white_list => %w{http https} } }
              end

              it "should include the white listed url schemes in the error message" do
                subject.valid?
                subject.errors[:remote_video_net_url].first.should include("http and https")
              end
            end
          end
        end

        context "on update" do
          before do
            subject.remote_video_net_url = "http$://example.com/some_video.mp4"
          end

          it "should be valid" do
            subject.save(:validate => false)
            subject.should be_valid
          end
        end
      end

      context "is turned off in the configuration" do
        before do
          DirectUploader.validate_remote_net_url_format = false
        end

        it "should not validate the format of the remote net url" do
          party_class.should_not_receive(:validates_remote_net_url_format_of)
          mount_uploader
        end
      end
    end

    describe ".validates_is_uploaded" do
      it "should be turned off by default" do
        party_class.should_not_receive(:validates_is_uploaded)
        mount_uploader
      end

      context "is turned on in the configuration" do
        before do
          DirectUploader.validate_is_uploaded = true
        end

        it "should validate that a file has been uploaded" do
          party_class.should_receive(:validates_is_uploaded).with(:video)
          mount_uploader
        end
      end

      context "is on" do
        before do
          party_class.validates_is_uploaded :video
        end

        context "where there is no upload" do
          it_should_behave_like "without an upload" do
            let(:remote_video_net_url) { nil }
            let(:upload_path) { nil }
          end
        end

        context "where the remote net url is blank" do
          it_should_behave_like "without an upload" do
            let(:remote_video_net_url) { "" }
            let(:upload_path) { nil }
          end
        end

        context "with an upload by remote url" do
          before do
            subject.remote_video_net_url = "http://example.com/some_url.anything"
          end

          it "should be valid" do
            subject.should be_valid
          end
        end

        context "with an upload by file" do
          before do
            subject.video_key = sample_key
          end

          it "should be valid" do
            subject.should be_valid
          end
        end
      end
    end

    describe ".validates_is_attached" do
      it "should be turned off by default" do
        party_class.should_not_receive(:validates_is_attached)
        mount_uploader
      end

      context "is turned on in the configuration" do
        before do
          DirectUploader.validate_is_attached = true
        end

        it "should validate that a file has been attached" do
          party_class.should_receive(:validates_is_attached).with(:video)
          mount_uploader
        end
      end

      context "is on" do
        before do
          party_class.validates_is_attached :video
        end

        context "where the attachment" do
          context "is blank" do
            it_should_behave_like "a blank or empty attachment"
          end

          context "is nil" do
            before do
              subject.video = nil
            end

            it_should_behave_like "a blank or empty attachment"
          end
        end
      end
    end

    it_should_have_accessor(:skip_is_attached_validations)

    describe "#key" do
      it "should be accessible" do
        party_class.new(:video_key => "some key").video_key.should == "some key"
      end
    end

    describe "#remote_\#\{column\}_net_url" do
      it "should be accessible" do
        party_class.new(:remote_video_net_url => "some url").remote_video_net_url.should == "some url"
      end
    end

    describe "#filename_valid?" do
      shared_examples_for "having empty errors" do
        before do
          subject.filename_valid?
        end

        context "where after the call, #errors" do
          it "should be empty" do
            subject.errors.should be_empty
          end
        end
      end

      context "does not have an upload" do
        it "should be true" do
          subject.filename_valid?.should be true
        end

        it_should_behave_like "having empty errors"
      end

      context "has an upload" do
        context "with a valid filename" do
          before do
            subject.video_key = sample_key(:model_class => subject.class)
          end

          it "should be true" do
            subject.filename_valid?.should be true
          end

          it_should_behave_like "having empty errors"
        end

        context "with an invalid filename" do
          before { subject.video_key = sample_key(:model_class => subject.class, :valid => false) }

          it "should be false" do
            subject.filename_valid?.should be false
          end

          context "after the call, #errors" do
            before { subject.filename_valid? }

            it "should only contain '\#\{column\}' errors" do
              subject.errors.count.should == subject.errors[:video].count
            end
          end
        end
      end
    end
  end

  describe "class Resource < ActiveRecord::Base; mount_uploader :file, DirectUploader; end" do
    include UploaderHelpers
    include ModelHelpers

    let(:resource_class) do
      Class.new(Resource)
    end

    let(:subject) do
      resource = resource_class.new
    end

    def mount_uploader
      resource_class.mount_uploader :file, DirectUploader
    end

    #See resource table migration
    it "should be valid still when a file column exists in table" do
      expect(subject).to be_valid
    end


  end
end
