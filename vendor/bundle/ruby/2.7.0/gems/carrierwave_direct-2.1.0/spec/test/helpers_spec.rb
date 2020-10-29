# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Test::Helpers do
  include CarrierWaveDirect::Test::Helpers

  describe "#sample_key" do
    context "passing an instance of DirectUploader mounted as a video" do
      let(:direct_uploader) { MountedClass.new.video }

      context "where its extension white list returns" do

        shared_examples_for "returning the default extension" do
          it "should return '*/guid/filename.extension'" do
            expect(sample_key(direct_uploader)).to match /#{GUID_REGEXP}\/filename\.extension$/
          end
        end

        context "['exe', 'bmp']" do
          before do
            allow(direct_uploader).to receive(:extension_whitelist).and_return(%w{exe bmp})
          end

          it "should return '*/guid/filename.exe'" do
            expect(sample_key(direct_uploader)).to match /#{GUID_REGEXP}\/filename\.exe$/
          end
        end

        context "[]" do
          before do
            allow(direct_uploader).to receive(:extension_whitelist).and_return([])
          end

          it_should_behave_like "returning the default extension"
        end

        context "nil" do
          before do
            allow(direct_uploader).to receive(:extension_whitelist).and_return(nil)
          end

          it_should_behave_like "returning the default extension"
        end

      end

      context "with no options" do
        it "should return '*/guid/filename.extension'" do
          expect(sample_key(direct_uploader)).to match /#{GUID_REGEXP}\/filename\.extension$/
        end
      end

      context "with options" do
        shared_examples_for "an invalid key" do
          it "should return 'filename.extension'" do
            key_parts = sample_key(direct_uploader, options).split("/")
            key_parts.pop
            key_parts.last.should_not =~ /^#{GUID_REGEXP}$/
          end
        end

        shared_examples_for "a custom filename" do
          it "should return '*/guid/some_file.reg'" do
            expect(sample_key(direct_uploader, options)).to match /#{GUID_REGEXP}\/some_file\.reg$/
          end
        end

        context ":invalid => true" do
          it_should_behave_like "an invalid key" do
            let(:options) { { :invalid => true } }
          end
        end

        context ":valid => false" do
          it_should_behave_like "an invalid key" do
            let(:options) { { :valid => false } }
          end
        end

        context ":base => 'upload_dir/porno/movie/${filename}'" do
          it "should return 'upload_dir/porno/movie/guid/filename.extension'" do
            expect(sample_key(
              direct_uploader,
              :base => "upload_dir/porno/movie/${filename}"
            )).to eq "upload_dir/porno/movie/filename.extension"
          end
        end
        context ":filename => 'some_file.reg'" do
          it_should_behave_like "a custom filename" do
            let(:options) { { :filename => "some_file.reg" } }
          end
        end
        context ":filename => 'some_file', :extension => 'reg'" do
          it_should_behave_like "a custom filename" do
            let(:options) { { :filename => "some_file", :extension => "reg" } }
          end
        end
      end
    end
  end
end

