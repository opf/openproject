# encoding: utf-8
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Policies::Aws4HmacSha256 do
  let(:subject) { described_class.new(uploader) }
  let(:uploader) { DirectUploader.new }
  let(:mounted_model) { MountedClass.new }
  let(:mounted_subject) { DirectUploader.new(mounted_model, sample(:mounted_as)) }

  describe "#direct_fog_hash" do
    it "should return the policy hash" do
      expect(subject.direct_fog_hash.keys).to eq([:key, :acl, :policy, :"X-Amz-Signature", :"X-Amz-Credential", :"X-Amz-Algorithm", :"X-Amz-Date", :uri])
      expect(subject.direct_fog_hash[:acl]).to eq 'public-read'
      expect(subject.direct_fog_hash[:key]).to match /\$\{filename\}/
      expect(subject.direct_fog_hash[:"X-Amz-Algorithm"]).to eq "AWS4-HMAC-SHA256"
      expect(subject.direct_fog_hash[:uri]).to eq "https://s3.amazonaws.com/AWS_FOG_DIRECTORY/"
    end
  end

  # http://aws.amazon.com/articles/1434?_encoding=UTF8
  #http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-UsingHTTPPOST.html
  describe "#policy" do
    def decoded_policy(options = {}, &block)
      instance = options.delete(:subject) || subject
      JSON.parse(Base64.decode64(instance.policy(options, &block)))
    end

    context "policy is given a block" do
      it "should yield the options to the block" do
        number = 0
        subject.policy do |conditions|
          number+=1
        end
        expect(number).to eq 1
      end
      it "should include new options in the conditions" do
        policy = subject.policy do |conditions|
          conditions << {"x-aws-storage-class" => "STANDARD"}
        end
        decoded = JSON.parse(Base64.decode64(policy))
        expect(decoded['conditions'].last['x-aws-storage-class']).to eq "STANDARD"
      end
    end

    it "should return Base64-encoded JSON" do
      expect(decoded_policy).to be_a(Hash)
    end

    it "should not contain any new lines" do
      expect(subject.policy).to_not include("\n")
    end

    it "should be cached" do
      Timecop.freeze(Time.now) do
        @policy_now = subject.policy
      end
      Timecop.freeze(1.second.from_now) do
        @policy_later = subject.policy
      end
      expect(@policy_later).to eql @policy_now
    end

    context "expiration" do
      def expiration(options = {})
        decoded_policy(options)["expiration"]
      end

      # JSON times have no seconds, so accept upto one second inaccuracy
      def have_expiration(expires_in = DirectUploader.upload_expiration)
        be_within(1.second).of (Time.now + expires_in)
      end

      it "should be valid ISO8601 and not use default Time#to_json" do
        Time.any_instance.stub(:to_json) { '"Invalid time"' } # JSON gem
        Time.any_instance.stub(:as_json) { '"Invalid time"' } # Active Support
        expect { Time.iso8601(expiration) }.to_not raise_error
      end

      it "should be #{DirectUploader.upload_expiration / 3600} hours from now" do
        Timecop.freeze(Time.now) do
          expect(Time.parse(expiration)).to have_expiration
        end
      end

      it "should be encoded as a utc time" do
        expect(Time.parse(expiration)).to be_utc
      end

      it "should be #{sample(:expiration) / 60 } minutes from now when passing {:expiration => #{sample(:expiration)}}" do
        Timecop.freeze(Time.now) do
          expect(Time.parse(expiration(:expiration => sample(:expiration)))).to have_expiration(sample(:expiration))
        end
      end
    end

    context "conditions" do
      def conditions(options = {})
        decoded_policy(options)["conditions"]
      end

      def have_condition(field, value = nil)
        field.is_a?(Hash) ? include(field) : include(["starts-with", "$#{field}", value.to_s])
      end

      context "should include" do
        it "'utf8' if enforce_ut8 is set" do
          expect(conditions(enforce_utf8: true)).to have_condition(:utf8)
        end

        it "'utf8' if enforce_ut8 is set" do
          expect(conditions).to_not have_condition(:utf8)
        end

        # S3 conditions
        it "'key'" do
          allow(mounted_subject).to receive(:key).and_return(sample(:s3_key))
          expect(conditions(
            :subject => mounted_subject
          )).to have_condition(:key, sample(:s3_key))
        end

        it "'key' without FILENAME_WILDCARD" do
          expect(conditions(
            :subject => mounted_subject
          )).to have_condition(:key, mounted_subject.key.sub("${filename}", ""))
        end

        it "'bucket'" do
          expect(conditions).to have_condition("bucket" => uploader.fog_directory)
        end

        it "'acl'" do
          expect(conditions).to have_condition("acl" => uploader.acl)
        end

        it "'success_action_redirect'" do
          uploader.success_action_redirect = "http://example.com/some_url"
          expect(conditions).to have_condition("success_action_redirect" => "http://example.com/some_url")
        end

        it "does not have 'content-type' when will_include_content_type is false" do
          allow(uploader.class).to receive(:will_include_content_type).and_return(false)
          expect(conditions).to_not have_condition('Content-Type')
        end

        it "has 'content-type' when will_include_content_type is true" do
          allow(uploader.class).to receive(:will_include_content_type).and_return(true)
          expect(conditions).to have_condition('Content-Type')
        end

        context 'when use_action_status is true' do
          before(:all) do
            DirectUploader.use_action_status = true
          end

          after(:all) do
            DirectUploader.use_action_status = false
          end

          it "'success_action_status'" do
            uploader.success_action_status = '200'
            expect(conditions).to have_condition("success_action_status" => "200")
          end

          it "does not have 'success_action_redirect'" do
            uploader.success_action_redirect = "http://example.com/some_url"
            expect(conditions).to_not have_condition("success_action_redirect" => "http://example.com/some_url")
          end
        end

        context "'content-length-range of'" do
          def have_content_length_range(options = {})
            include([
              "content-length-range",
              options[:min_file_size] || DirectUploader.min_file_size,
              options[:max_file_size] || DirectUploader.max_file_size,
            ])
          end

          it "#{DirectUploader.min_file_size} bytes" do
            expect(conditions).to have_content_length_range
          end

          it "#{DirectUploader.max_file_size} bytes" do
            expect(conditions).to have_content_length_range
          end

          it "#{sample(:min_file_size)} bytes when passing {:min_file_size => #{sample(:min_file_size)}}" do
            expect(conditions(
              :min_file_size => sample(:min_file_size)
            )).to have_content_length_range(:min_file_size => sample(:min_file_size))
          end

          it "#{sample(:max_file_size)} bytes when passing {:max_file_size => #{sample(:max_file_size)}}" do
            expect(conditions(
              :max_file_size => sample(:max_file_size)
            )).to have_content_length_range(:max_file_size => sample(:max_file_size))
          end
        end
      end
    end
  end

  describe "clear!" do
    it "should reset the cached policy string" do
      Timecop.freeze(Time.now) do
        @policy_now = subject.policy
      end
      subject.clear!

      Timecop.freeze(1.second.from_now) do
        @policy_after_reset = subject.policy
      end
      expect(@policy_after_reset).not_to eql @policy_now
    end
  end

  describe "#signature" do
    it "should not contain any new lines" do
      expect(subject.signature).to_not include("\n")
    end

    it "should return a HMAC hexdigest encoded 'sha256' hash of the secret key and policy document" do
      expect(subject.signature).to eq OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha256'),
        subject.signing_key, subject.policy
      )
    end
  end
  #http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-UsingHTTPPOST.html
  describe "#signature_key" do
    it "should include correct signature_key elements" do
      kDate    = OpenSSL::HMAC.digest('sha256', "AWS4" + uploader.aws_secret_access_key, Time.now.utc.strftime("%Y%m%d"))
      kRegion  = OpenSSL::HMAC.digest('sha256', kDate, uploader.region)
      kService = OpenSSL::HMAC.digest('sha256', kRegion, 's3')
      kSigning = OpenSSL::HMAC.digest('sha256', kService, "aws4_request")

      expect(subject.signing_key).to eq (kSigning)
    end
  end
end

