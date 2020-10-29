# frozen_string_literal: true

require 'aws-sigv4'

module Aws
  module STS
    # Allows you to create presigned URLs for STS operations.
    #
    # @example
    #
    #   signer = Aws::STS::Presigner.new
    #   url = signer.get_caller_identity_presigned_url(
    #     headers: {"X-K8s-Aws-Id" => 'my-eks-cluster'}
    #   )
    class Presigner
      # @option options [Client] :client Optionally provide an existing
      #   STS client
      def initialize(options = {})
        @client = options[:client] || Aws::STS::Client.new
      end

      # Returns a presigned url for get_caller_identity.
      #
      # @option options [Hash] :headers
      #   Headers that should be signed and sent along with the request. All
      #   x-amz-* headers must be present during signing. Other headers are
      #   optional.
      #
      # @return [String] A presigned url string.
      #
      # @example
      #
      #   url = signer.get_caller_identity_presigned_url(
      #     headers: {"X-K8s-Aws-Id" => 'my-eks-cluster'},
      #   )
      #
      # This can be easily converted to a token used by the EKS service:
      # {https://ruby-doc.org/stdlib-2.3.1/libdoc/base64/rdoc/Base64.html#method-i-encode64}
      # "k8s-aws-v1." + Base64.urlsafe_encode64(url).chomp("==")
      def get_caller_identity_presigned_url(options = {})
        req = @client.build_request(:get_session_token, {})

        param_list = Aws::Query::ParamList.new
        param_list.set('Action', 'GetCallerIdentity')
        param_list.set('Version', req.context.config.api.version)
        Aws::Query::EC2ParamBuilder.new(param_list)
          .apply(req.context.operation.input, {})

        signer = Aws::Sigv4::Signer.new(
          service: 'sts',
          region: req.context.config.region,
          credentials_provider: req.context.config.credentials
        )

        url = Aws::Partitions::EndpointProvider.resolve(
          req.context.config.region, 'sts', 'regional'
        )
        url += "/?#{param_list}"

        signer.presign_url(
          http_method: 'GET',
          url: url,
          body: '',
          headers: options[:headers]
        ).to_s
      end
    end
  end
end
