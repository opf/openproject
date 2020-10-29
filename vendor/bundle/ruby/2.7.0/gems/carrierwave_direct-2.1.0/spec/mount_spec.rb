# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Mount do
  include ModelHelpers

  class Gathering
    extend CarrierWave::Mount
    extend CarrierWaveDirect::Mount
    mount_uploader :video, DirectUploader
  end

  context "class Gathering; extend CarrierWave::Mount; extend CarrierWaveDirect::Mount; mount_uploader :video, DirectUploader; end" do
    let(:subject) { Gathering.new }

    it_should_have_accessor(:remote_video_net_url)

    describe "#has_video_upload?" do
      it "returns false when video does not have a key" do
        subject.video.key = nil
        expect(subject).to_not have_video_upload
      end

      it "returns true when video has a key" do
        subject.video.key = sample(:s3_key)
        expect(subject).to have_video_upload
      end
    end

    describe "#has_remote_video_net_url?" do
      it "returns false when remote_video_net_url is nil" do
        subject.remote_video_net_url = nil
        expect(subject).to_not have_remote_video_net_url
      end

      it "returns true when remote_video_net_url is not nil" do
        subject.remote_video_net_url = :not_nil
        expect(subject).to have_remote_video_net_url
      end
    end

    it_should_delegate(:video_key, :to => "video#key", :accessible => { "has_video_upload?" => false })
  end
end

