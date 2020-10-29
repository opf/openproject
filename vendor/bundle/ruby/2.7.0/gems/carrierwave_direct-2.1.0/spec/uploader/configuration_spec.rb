require 'spec_helper'

describe CarrierWaveDirect::Uploader::Configuration do
  include UploaderHelpers
  include ModelHelpers

  let(:subject) { DirectUploader }

  before do
    subject.reset_direct_config
  end

  describe "default configuration" do
    it "returns false for validate_is_attached" do
      expect(subject.validate_is_attached).to be false
    end

    it "returns false for validate_is_uploaded" do
      expect(subject.validate_is_uploaded).to be false
    end

    it "return true for validate_unique_filename" do
      expect(subject.validate_unique_filename).to be true
    end

    it "returns true for validate_remote_net_url_format" do
      expect(subject.validate_remote_net_url_format).to be true
    end

    it "has upload_expiration of 10 hours" do
      expect(subject.upload_expiration).to eq 36000
    end

    it "has min_file_size of 1 byte" do
      expect(subject.min_file_size).to eq 1
    end

    it "has max_file_size of 5 MB" do
      expect(subject.max_file_size).to eq 5242880
    end

    it "returns false for use_action_status" do
      expect(subject.use_action_status).to be false
    end
  end
end
