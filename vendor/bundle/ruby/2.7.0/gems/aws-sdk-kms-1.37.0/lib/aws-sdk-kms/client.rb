# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

require 'seahorse/client/plugins/content_length.rb'
require 'aws-sdk-core/plugins/credentials_configuration.rb'
require 'aws-sdk-core/plugins/logging.rb'
require 'aws-sdk-core/plugins/param_converter.rb'
require 'aws-sdk-core/plugins/param_validator.rb'
require 'aws-sdk-core/plugins/user_agent.rb'
require 'aws-sdk-core/plugins/helpful_socket_errors.rb'
require 'aws-sdk-core/plugins/retry_errors.rb'
require 'aws-sdk-core/plugins/global_configuration.rb'
require 'aws-sdk-core/plugins/regional_endpoint.rb'
require 'aws-sdk-core/plugins/endpoint_discovery.rb'
require 'aws-sdk-core/plugins/endpoint_pattern.rb'
require 'aws-sdk-core/plugins/response_paging.rb'
require 'aws-sdk-core/plugins/stub_responses.rb'
require 'aws-sdk-core/plugins/idempotency_token.rb'
require 'aws-sdk-core/plugins/jsonvalue_converter.rb'
require 'aws-sdk-core/plugins/client_metrics_plugin.rb'
require 'aws-sdk-core/plugins/client_metrics_send_plugin.rb'
require 'aws-sdk-core/plugins/transfer_encoding.rb'
require 'aws-sdk-core/plugins/http_checksum.rb'
require 'aws-sdk-core/plugins/signature_v4.rb'
require 'aws-sdk-core/plugins/protocols/json_rpc.rb'

Aws::Plugins::GlobalConfiguration.add_identifier(:kms)

module Aws::KMS
  # An API client for KMS.  To construct a client, you need to configure a `:region` and `:credentials`.
  #
  #     client = Aws::KMS::Client.new(
  #       region: region_name,
  #       credentials: credentials,
  #       # ...
  #     )
  #
  # For details on configuring region and credentials see
  # the [developer guide](/sdk-for-ruby/v3/developer-guide/setup-config.html).
  #
  # See {#initialize} for a full list of supported configuration options.
  class Client < Seahorse::Client::Base

    include Aws::ClientStubs

    @identifier = :kms

    set_api(ClientApi::API)

    add_plugin(Seahorse::Client::Plugins::ContentLength)
    add_plugin(Aws::Plugins::CredentialsConfiguration)
    add_plugin(Aws::Plugins::Logging)
    add_plugin(Aws::Plugins::ParamConverter)
    add_plugin(Aws::Plugins::ParamValidator)
    add_plugin(Aws::Plugins::UserAgent)
    add_plugin(Aws::Plugins::HelpfulSocketErrors)
    add_plugin(Aws::Plugins::RetryErrors)
    add_plugin(Aws::Plugins::GlobalConfiguration)
    add_plugin(Aws::Plugins::RegionalEndpoint)
    add_plugin(Aws::Plugins::EndpointDiscovery)
    add_plugin(Aws::Plugins::EndpointPattern)
    add_plugin(Aws::Plugins::ResponsePaging)
    add_plugin(Aws::Plugins::StubResponses)
    add_plugin(Aws::Plugins::IdempotencyToken)
    add_plugin(Aws::Plugins::JsonvalueConverter)
    add_plugin(Aws::Plugins::ClientMetricsPlugin)
    add_plugin(Aws::Plugins::ClientMetricsSendPlugin)
    add_plugin(Aws::Plugins::TransferEncoding)
    add_plugin(Aws::Plugins::HttpChecksum)
    add_plugin(Aws::Plugins::SignatureV4)
    add_plugin(Aws::Plugins::Protocols::JsonRpc)

    # @overload initialize(options)
    #   @param [Hash] options
    #   @option options [required, Aws::CredentialProvider] :credentials
    #     Your AWS credentials. This can be an instance of any one of the
    #     following classes:
    #
    #     * `Aws::Credentials` - Used for configuring static, non-refreshing
    #       credentials.
    #
    #     * `Aws::SharedCredentials` - Used for loading static credentials from a
    #       shared file, such as `~/.aws/config`.
    #
    #     * `Aws::AssumeRoleCredentials` - Used when you need to assume a role.
    #
    #     * `Aws::AssumeRoleWebIdentityCredentials` - Used when you need to
    #       assume a role after providing credentials via the web.
    #
    #     * `Aws::SSOCredentials` - Used for loading credentials from AWS SSO using an
    #       access token generated from `aws login`.
    #
    #     * `Aws::ProcessCredentials` - Used for loading credentials from a
    #       process that outputs to stdout.
    #
    #     * `Aws::InstanceProfileCredentials` - Used for loading credentials
    #       from an EC2 IMDS on an EC2 instance.
    #
    #     * `Aws::ECSCredentials` - Used for loading credentials from
    #       instances running in ECS.
    #
    #     * `Aws::CognitoIdentityCredentials` - Used for loading credentials
    #       from the Cognito Identity service.
    #
    #     When `:credentials` are not configured directly, the following
    #     locations will be searched for credentials:
    #
    #     * `Aws.config[:credentials]`
    #     * The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
    #     * ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #     * EC2/ECS IMDS instance profile - When used by default, the timeouts
    #       are very aggressive. Construct and pass an instance of
    #       `Aws::InstanceProfileCredentails` or `Aws::ECSCredentials` to
    #       enable retries and extended timeouts.
    #
    #   @option options [required, String] :region
    #     The AWS region to connect to.  The configured `:region` is
    #     used to determine the service `:endpoint`. When not passed,
    #     a default `:region` is searched for in the following locations:
    #
    #     * `Aws.config[:region]`
    #     * `ENV['AWS_REGION']`
    #     * `ENV['AMAZON_REGION']`
    #     * `ENV['AWS_DEFAULT_REGION']`
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #
    #   @option options [String] :access_key_id
    #
    #   @option options [Boolean] :active_endpoint_cache (false)
    #     When set to `true`, a thread polling for endpoints will be running in
    #     the background every 60 secs (default). Defaults to `false`.
    #
    #   @option options [Boolean] :adaptive_retry_wait_to_fill (true)
    #     Used only in `adaptive` retry mode.  When true, the request will sleep
    #     until there is sufficent client side capacity to retry the request.
    #     When false, the request will raise a `RetryCapacityNotAvailableError` and will
    #     not retry instead of sleeping.
    #
    #   @option options [Boolean] :client_side_monitoring (false)
    #     When `true`, client-side metrics will be collected for all API requests from
    #     this client.
    #
    #   @option options [String] :client_side_monitoring_client_id ("")
    #     Allows you to provide an identifier for this client which will be attached to
    #     all generated client side metrics. Defaults to an empty string.
    #
    #   @option options [String] :client_side_monitoring_host ("127.0.0.1")
    #     Allows you to specify the DNS hostname or IPv4 or IPv6 address that the client
    #     side monitoring agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Integer] :client_side_monitoring_port (31000)
    #     Required for publishing client metrics. The port that the client side monitoring
    #     agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Aws::ClientSideMonitoring::Publisher] :client_side_monitoring_publisher (Aws::ClientSideMonitoring::Publisher)
    #     Allows you to provide a custom client-side monitoring publisher class. By default,
    #     will use the Client Side Monitoring Agent Publisher.
    #
    #   @option options [Boolean] :convert_params (true)
    #     When `true`, an attempt is made to coerce request parameters into
    #     the required types.
    #
    #   @option options [Boolean] :correct_clock_skew (true)
    #     Used only in `standard` and adaptive retry modes. Specifies whether to apply
    #     a clock skew correction and retry requests with skewed client clocks.
    #
    #   @option options [Boolean] :disable_host_prefix_injection (false)
    #     Set to true to disable SDK automatically adding host prefix
    #     to default service endpoint when available.
    #
    #   @option options [String] :endpoint
    #     The client endpoint is normally constructed from the `:region`
    #     option. You should only configure an `:endpoint` when connecting
    #     to test or custom endpoints. This should be a valid HTTP(S) URI.
    #
    #   @option options [Integer] :endpoint_cache_max_entries (1000)
    #     Used for the maximum size limit of the LRU cache storing endpoints data
    #     for endpoint discovery enabled operations. Defaults to 1000.
    #
    #   @option options [Integer] :endpoint_cache_max_threads (10)
    #     Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
    #
    #   @option options [Integer] :endpoint_cache_poll_interval (60)
    #     When :endpoint_discovery and :active_endpoint_cache is enabled,
    #     Use this option to config the time interval in seconds for making
    #     requests fetching endpoints information. Defaults to 60 sec.
    #
    #   @option options [Boolean] :endpoint_discovery (false)
    #     When set to `true`, endpoint discovery will be enabled for operations when available.
    #
    #   @option options [Aws::Log::Formatter] :log_formatter (Aws::Log::Formatter.default)
    #     The log formatter.
    #
    #   @option options [Symbol] :log_level (:info)
    #     The log level to send messages to the `:logger` at.
    #
    #   @option options [Logger] :logger
    #     The Logger instance to send log messages to.  If this option
    #     is not set, logging will be disabled.
    #
    #   @option options [Integer] :max_attempts (3)
    #     An integer representing the maximum number attempts that will be made for
    #     a single request, including the initial attempt.  For example,
    #     setting this value to 5 will result in a request being retried up to
    #     4 times. Used in `standard` and `adaptive` retry modes.
    #
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file
    #     at HOME/.aws/credentials.  When not specified, 'default' is used.
    #
    #   @option options [Proc] :retry_backoff
    #     A proc or lambda used for backoff. Defaults to 2**retries * retry_base_delay.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Float] :retry_base_delay (0.3)
    #     The base delay in seconds used by the default backoff function. This option
    #     is only used in the `legacy` retry mode.
    #
    #   @option options [Symbol] :retry_jitter (:none)
    #     A delay randomiser function used by the default backoff function.
    #     Some predefined functions can be referenced by name - :none, :equal, :full,
    #     otherwise a Proc that takes and returns a number. This option is only used
    #     in the `legacy` retry mode.
    #
    #     @see https://www.awsarchitectureblog.com/2015/03/backoff.html
    #
    #   @option options [Integer] :retry_limit (3)
    #     The maximum number of times to retry failed requests.  Only
    #     ~ 500 level server errors and certain ~ 400 level client errors
    #     are retried.  Generally, these are throttling errors, data
    #     checksum errors, networking errors, timeout errors, auth errors,
    #     endpoint discovery, and errors from expired credentials.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Integer] :retry_max_delay (0)
    #     The maximum number of seconds to delay between retries (0 for no limit)
    #     used by the default backoff function. This option is only used in the
    #     `legacy` retry mode.
    #
    #   @option options [String] :retry_mode ("legacy")
    #     Specifies which retry algorithm to use. Values are:
    #
    #     * `legacy` - The pre-existing retry behavior.  This is default value if
    #       no retry mode is provided.
    #
    #     * `standard` - A standardized set of retry rules across the AWS SDKs.
    #       This includes support for retry quotas, which limit the number of
    #       unsuccessful retries a client can make.
    #
    #     * `adaptive` - An experimental retry mode that includes all the
    #       functionality of `standard` mode along with automatic client side
    #       throttling.  This is a provisional mode that may change behavior
    #       in the future.
    #
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [Boolean] :simple_json (false)
    #     Disables request parameter conversion, validation, and formatting.
    #     Also disable response data type conversions. This option is useful
    #     when you want to ensure the highest level of performance by
    #     avoiding overhead of walking request parameters and response data
    #     structures.
    #
    #     When `:simple_json` is enabled, the request parameters hash must
    #     be formatted exactly as the DynamoDB API expects.
    #
    #   @option options [Boolean] :stub_responses (false)
    #     Causes the client to return stubbed responses. By default
    #     fake responses are generated and returned. You can specify
    #     the response data to return or errors to raise by calling
    #     {ClientStubs#stub_responses}. See {ClientStubs} for more information.
    #
    #     ** Please note ** When response stubbing is enabled, no HTTP
    #     requests are made, and retries are disabled.
    #
    #   @option options [Boolean] :validate_params (true)
    #     When `true`, request parameters are validated before
    #     sending the request.
    #
    #   @option options [URI::HTTP,String] :http_proxy A proxy to send
    #     requests through.  Formatted like 'http://proxy.com:123'.
    #
    #   @option options [Float] :http_open_timeout (15) The number of
    #     seconds to wait when opening a HTTP session before raising a
    #     `Timeout::Error`.
    #
    #   @option options [Integer] :http_read_timeout (60) The default
    #     number of seconds to wait for response data.  This value can
    #     safely be set per-request on the session.
    #
    #   @option options [Float] :http_idle_timeout (5) The number of
    #     seconds a connection is allowed to sit idle before it is
    #     considered stale.  Stale connections are closed and removed
    #     from the pool before making a request.
    #
    #   @option options [Float] :http_continue_timeout (1) The number of
    #     seconds to wait for a 100-continue response before sending the
    #     request body.  This option has no effect unless the request has
    #     "Expect" header set to "100-continue".  Defaults to `nil` which
    #     disables this behaviour.  This value can safely be set per
    #     request on the session.
    #
    #   @option options [Boolean] :http_wire_trace (false) When `true`,
    #     HTTP debug output will be sent to the `:logger`.
    #
    #   @option options [Boolean] :ssl_verify_peer (true) When `true`,
    #     SSL peer certificates are verified when establishing a
    #     connection.
    #
    #   @option options [String] :ssl_ca_bundle Full path to the SSL
    #     certificate authority bundle file that should be used when
    #     verifying peer certificates.  If you do not pass
    #     `:ssl_ca_bundle` or `:ssl_ca_directory` the the system default
    #     will be used if available.
    #
    #   @option options [String] :ssl_ca_directory Full path of the
    #     directory that contains the unbundled SSL certificate
    #     authority files for verifying peer certificates.  If you do
    #     not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the
    #     system default will be used if available.
    #
    def initialize(*args)
      super
    end

    # @!group API Operations

    # Cancels the deletion of a customer master key (CMK). When this
    # operation succeeds, the key state of the CMK is `Disabled`. To enable
    # the CMK, use EnableKey. You cannot perform this operation on a CMK in
    # a different AWS account.
    #
    # For more information about scheduling and canceling deletion of a CMK,
    # see [Deleting Customer Master Keys][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier for the customer master key (CMK) for which to
    #   cancel deletion.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::CancelKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CancelKeyDeletionResponse#key_id #key_id} => String
    #
    #
    # @example Example: To cancel deletion of a customer master key (CMK)
    #
    #   # The following example cancels deletion of the specified CMK.
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose deletion you are canceling. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK whose deletion you canceled.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CancelKeyDeletion AWS API Documentation
    #
    # @overload cancel_key_deletion(params = {})
    # @param [Hash] params ({})
    def cancel_key_deletion(params = {}, options = {})
      req = build_request(:cancel_key_deletion, params)
      req.send_request(options)
    end

    # Connects or reconnects a [custom key store][1] to its associated AWS
    # CloudHSM cluster.
    #
    # The custom key store must be connected before you can create customer
    # master keys (CMKs) in the key store or use the CMKs it contains. You
    # can disconnect and reconnect a custom key store at any time.
    #
    # To connect a custom key store, its associated AWS CloudHSM cluster
    # must have at least one active HSM. To get the number of active HSMs in
    # a cluster, use the [DescribeClusters][2] operation. To add HSMs to the
    # cluster, use the [CreateHsm][3] operation. Also, the [ `kmsuser`
    # crypto user][4] (CU) must not be logged into the cluster. This
    # prevents AWS KMS from using this account to log in.
    #
    # The connection process can take an extended amount of time to
    # complete; up to 20 minutes. This operation starts the connection
    # process, but it does not wait for it to complete. When it succeeds,
    # this operation quickly returns an HTTP 200 response and a JSON object
    # with no properties. However, this response does not indicate that the
    # custom key store is connected. To get the connection state of the
    # custom key store, use the DescribeCustomKeyStores operation.
    #
    # During the connection process, AWS KMS finds the AWS CloudHSM cluster
    # that is associated with the custom key store, creates the connection
    # infrastructure, connects to the cluster, logs into the AWS CloudHSM
    # client as the `kmsuser` CU, and rotates its password.
    #
    # The `ConnectCustomKeyStore` operation might fail for various reasons.
    # To find the reason, use the DescribeCustomKeyStores operation and see
    # the `ConnectionErrorCode` in the response. For help interpreting the
    # `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # To fix the failure, use the DisconnectCustomKeyStore operation to
    # disconnect the custom key store, correct the error, use the
    # UpdateCustomKeyStore operation if necessary, and then use
    # `ConnectCustomKeyStore` again.
    #
    # If you are having trouble connecting or disconnecting a custom key
    # store, see [Troubleshooting a Custom Key Store][5] in the *AWS Key
    # Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    # [3]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the key store ID of the custom key store that you want to
    #   connect. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.connect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ConnectCustomKeyStore AWS API Documentation
    #
    # @overload connect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def connect_custom_key_store(params = {}, options = {})
      req = build_request(:connect_custom_key_store, params)
      req.send_request(options)
    end

    # Creates a display name for a customer managed customer master key
    # (CMK). You can use an alias to identify a CMK in [cryptographic
    # operations][1], such as Encrypt and GenerateDataKey. You can change
    # the CMK associated with the alias at any time.
    #
    # Aliases are easier to remember than key IDs. They can also help to
    # simplify your applications. For example, if you use an alias in your
    # code, you can change the CMK your code uses by associating a given
    # alias with a different CMK.
    #
    # To run the same code in multiple AWS regions, use an alias in your
    # code, such as `alias/ApplicationKey`. Then, in each AWS Region, create
    # an `alias/ApplicationKey` alias that is associated with a CMK in that
    # Region. When you run your code, it uses the `alias/ApplicationKey` CMK
    # for that AWS Region without any Region-specific code.
    #
    # This operation does not return a response. To get the alias that you
    # created, use the ListAliases operation.
    #
    # To use aliases successfully, be aware of the following information.
    #
    # * Each alias points to only one CMK at a time, although a single CMK
    #   can have multiple aliases. The alias and its associated CMK must be
    #   in the same AWS account and Region.
    #
    # * You can associate an alias with any customer managed CMK in the same
    #   AWS account and Region. However, you do not have permission to
    #   associate an alias with an [AWS managed CMK][2] or an [AWS owned
    #   CMK][3].
    #
    # * To change the CMK associated with an alias, use the UpdateAlias
    #   operation. The current CMK and the new CMK must be the same type
    #   (both symmetric or both asymmetric) and they must have the same key
    #   usage (`ENCRYPT_DECRYPT` or `SIGN_VERIFY`). This restriction
    #   prevents cryptographic errors in code that uses aliases.
    #
    # * The alias name must begin with `alias/` followed by a name, such as
    #   `alias/ExampleAlias`. It can contain only alphanumeric characters,
    #   forward slashes (/), underscores (\_), and dashes (-). The alias
    #   name cannot begin with `alias/aws/`. The `alias/aws/` prefix is
    #   reserved for [AWS managed CMKs][2].
    #
    # * The alias name must be unique within an AWS Region. However, you can
    #   use the same alias name in multiple Regions of the same AWS account.
    #   Each instance of the alias is associated with a CMK in its Region.
    #
    # * After you create an alias, you cannot change its alias name.
    #   However, you can use the DeleteAlias operation to delete the alias
    #   and then create a new alias with the desired name.
    #
    # * You can use an alias name or alias ARN to identify a CMK in AWS KMS
    #   [cryptographic operations][1] and in the DescribeKey operation.
    #   However, you cannot use alias names or alias ARNs in API operations
    #   that manage CMKs, such as DisableKey or GetKeyPolicy. For
    #   information about the valid CMK identifiers for each AWS KMS API
    #   operation, see the descriptions of the `KeyId` parameter in the API
    #   operation documentation.
    #
    # Because an alias is not a property of a CMK, you can delete and change
    # the aliases of a CMK without affecting the CMK. Also, aliases do not
    # appear in the response from the DescribeKey operation. To get the
    # aliases and alias ARNs of CMKs in each AWS account and Region, use the
    # ListAliases operation.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][4] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :alias_name
    #   Specifies the alias name. This value must begin with `alias/` followed
    #   by a name, such as `alias/ExampleAlias`. The alias name cannot begin
    #   with `alias/aws/`. The `alias/aws/` prefix is reserved for AWS managed
    #   CMKs.
    #
    # @option params [required, String] :target_key_id
    #   Identifies the CMK to which the alias refers. Specify the key ID or
    #   the Amazon Resource Name (ARN) of the CMK. You cannot specify another
    #   alias. For help finding the key ID and ARN, see [Finding the Key ID
    #   and ARN][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/viewing-keys.html#find-cmk-id-arn
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To create an alias
    #
    #   # The following example creates an alias for the specified customer master key (CMK).
    #
    #   resp = client.create_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to create. Aliases must begin with 'alias/'. Do not use aliases that begin with 'alias/aws' because they are reserved for use by AWS.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose alias you are creating. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateAlias AWS API Documentation
    #
    # @overload create_alias(params = {})
    # @param [Hash] params ({})
    def create_alias(params = {}, options = {})
      req = build_request(:create_alias, params)
      req.send_request(options)
    end

    # Creates a [custom key store][1] that is associated with an [AWS
    # CloudHSM cluster][2] that you own and manage.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    # Before you create the custom key store, you must assemble the required
    # elements, including an AWS CloudHSM cluster that fulfills the
    # requirements for a custom key store. For details about the required
    # elements, see [Assemble the Prerequisites][3] in the *AWS Key
    # Management Service Developer Guide*.
    #
    # When the operation completes successfully, it returns the ID of the
    # new custom key store. Before you can use your new custom key store,
    # you need to use the ConnectCustomKeyStore operation to connect the new
    # key store to its AWS CloudHSM cluster. Even if you are not going to
    # use your custom key store immediately, you might want to connect it to
    # verify that all settings are correct and then disconnect it until you
    # are ready to use it.
    #
    # For help with failures, see [Troubleshooting a Custom Key Store][4] in
    # the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [required, String] :custom_key_store_name
    #   Specifies a friendly name for the custom key store. The name must be
    #   unique in your AWS account.
    #
    # @option params [required, String] :cloud_hsm_cluster_id
    #   Identifies the AWS CloudHSM cluster for the custom key store. Enter
    #   the cluster ID of any active AWS CloudHSM cluster that is not already
    #   associated with a custom key store. To find the cluster ID, use the
    #   [DescribeClusters][1] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @option params [required, String] :trust_anchor_certificate
    #   Enter the content of the trust anchor certificate for the cluster.
    #   This is the content of the `customerCA.crt` file that you created when
    #   you [initialized the cluster][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html
    #
    # @option params [required, String] :key_store_password
    #   Enter the password of the [ `kmsuser` crypto user (CU) account][1] in
    #   the specified AWS CloudHSM cluster. AWS KMS logs into the cluster as
    #   this user to manage key material on your behalf.
    #
    #   The password must be a string of 7 to 32 characters. Its value is case
    #   sensitive.
    #
    #   This parameter tells AWS KMS the `kmsuser` account password; it does
    #   not change the password in the AWS CloudHSM cluster.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    #
    # @return [Types::CreateCustomKeyStoreResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateCustomKeyStoreResponse#custom_key_store_id #custom_key_store_id} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_custom_key_store({
    #     custom_key_store_name: "CustomKeyStoreNameType", # required
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType", # required
    #     trust_anchor_certificate: "TrustAnchorCertificateType", # required
    #     key_store_password: "KeyStorePasswordType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_store_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateCustomKeyStore AWS API Documentation
    #
    # @overload create_custom_key_store(params = {})
    # @param [Hash] params ({})
    def create_custom_key_store(params = {}, options = {})
      req = build_request(:create_custom_key_store, params)
      req.send_request(options)
    end

    # Adds a grant to a customer master key (CMK). The grant allows the
    # grantee principal to use the CMK when the conditions specified in the
    # grant are met. When setting permissions, grants are an alternative to
    # key policies.
    #
    # To create a grant that allows a [cryptographic operation][1] only when
    # the request includes a particular [encryption context][2], use the
    # `Constraints` parameter. For details, see GrantConstraints.
    #
    # You can create grants on symmetric and asymmetric CMKs. However, if
    # the grant allows an operation that the CMK does not support,
    # `CreateGrant` fails with a `ValidationException`.
    #
    # * Grants for symmetric CMKs cannot allow operations that are not
    #   supported for symmetric CMKs, including Sign, Verify, and
    #   GetPublicKey. (There are limited exceptions to this rule for legacy
    #   operations, but you should not create a grant for an operation that
    #   AWS KMS does not support.)
    #
    # * Grants for asymmetric CMKs cannot allow operations that are not
    #   supported for asymmetric CMKs, including operations that [generate
    #   data keys][3] or [data key pairs][4], or operations related to
    #   [automatic key rotation][5], [imported key material][6], or CMKs in
    #   [custom key stores][7].
    #
    # * Grants for asymmetric CMKs with a `KeyUsage` of `ENCRYPT_DECRYPT`
    #   cannot allow the Sign or Verify operations. Grants for asymmetric
    #   CMKs with a `KeyUsage` of `SIGN_VERIFY` cannot allow the Encrypt or
    #   Decrypt operations.
    #
    # * Grants for asymmetric CMKs cannot include an encryption context
    #   grant constraint. An encryption context is not supported on
    #   asymmetric CMKs.
    #
    # For information about symmetric and asymmetric CMKs, see [Using
    # Symmetric and Asymmetric CMKs][8] in the *AWS Key Management Service
    # Developer Guide*.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter. For more
    # information about grants, see [Grants][9] in the <i> <i>AWS Key
    # Management Service Developer Guide</i> </i>.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][10] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey
    # [4]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier for the customer master key (CMK) that the grant
    #   applies to.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :grantee_principal
    #   The principal that is given permission to perform the operations that
    #   the grant permits.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, IAM roles, federated users, and assumed role users. For
    #   examples of the ARN syntax to use for specifying a principal, see [AWS
    #   Identity and Access Management (IAM)][2] in the Example ARNs section
    #   of the *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @option params [String] :retiring_principal
    #   The principal that is given permission to retire the grant by using
    #   RetireGrant operation.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, federated users, and assumed role users. For examples of
    #   the ARN syntax to use for specifying a principal, see [AWS Identity
    #   and Access Management (IAM)][2] in the Example ARNs section of the
    #   *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @option params [required, Array<String>] :operations
    #   A list of operations that the grant permits.
    #
    # @option params [Types::GrantConstraints] :constraints
    #   Allows a [cryptographic operation][1] only when the encryption context
    #   matches or includes the encryption context specified in this
    #   structure. For more information about encryption context, see
    #   [Encryption Context][2] in the <i> <i>AWS Key Management Service
    #   Developer Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @option params [String] :name
    #   A friendly name for identifying the grant. Use this value to prevent
    #   the unintended creation of duplicate grants when retrying this
    #   request.
    #
    #   When this value is absent, all `CreateGrant` requests result in a new
    #   grant with a unique `GrantId` even if all the supplied parameters are
    #   identical. This can result in unintended duplicates when you retry the
    #   `CreateGrant` request.
    #
    #   When this value is present, you can retry a `CreateGrant` request with
    #   identical parameters; if the grant already exists, the original
    #   `GrantId` is returned without creating a new grant. Note that the
    #   returned grant token is unique with every `CreateGrant` request, even
    #   when a duplicate `GrantId` is returned. All grant tokens obtained in
    #   this way can be used interchangeably.
    #
    # @return [Types::CreateGrantResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateGrantResponse#grant_token #grant_token} => String
    #   * {Types::CreateGrantResponse#grant_id #grant_id} => String
    #
    #
    # @example Example: To create a grant
    #
    #   # The following example creates a grant that allows the specified IAM role to encrypt data with the specified customer
    #   # master key (CMK).
    #
    #   resp = client.create_grant({
    #     grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The identity that is given permission to perform the operations specified in the grant.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to which the grant applies. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     operations: [
    #       "Encrypt", 
    #       "Decrypt", 
    #     ], # A list of operations that the grant allows.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The unique identifier of the grant.
    #     grant_token: "AQpAM2RhZTk1MGMyNTk2ZmZmMzEyYWVhOWViN2I1MWM4Mzc0MWFiYjc0ZDE1ODkyNGFlNTIzODZhMzgyZjBlNGY3NiKIAgEBAgB4Pa6VDCWW__MSrqnre1HIN0Grt00ViSSuUjhqOC8OT3YAAADfMIHcBgkqhkiG9w0BBwaggc4wgcsCAQAwgcUGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMmqLyBTAegIn9XlK5AgEQgIGXZQjkBcl1dykDdqZBUQ6L1OfUivQy7JVYO2-ZJP7m6f1g8GzV47HX5phdtONAP7K_HQIflcgpkoCqd_fUnE114mSmiagWkbQ5sqAVV3ov-VeqgrvMe5ZFEWLMSluvBAqdjHEdMIkHMlhlj4ENZbzBfo9Wxk8b8SnwP4kc4gGivedzFXo-dwN8fxjjq_ZZ9JFOj2ijIbj5FyogDCN0drOfi8RORSEuCEmPvjFRMFAwcmwFkN2NPp89amA", # The grant token.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_grant({
    #     key_id: "KeyIdType", # required
    #     grantee_principal: "PrincipalIdType", # required
    #     retiring_principal: "PrincipalIdType",
    #     operations: ["Decrypt"], # required, accepts Decrypt, Encrypt, GenerateDataKey, GenerateDataKeyWithoutPlaintext, ReEncryptFrom, ReEncryptTo, Sign, Verify, GetPublicKey, CreateGrant, RetireGrant, DescribeKey, GenerateDataKeyPair, GenerateDataKeyPairWithoutPlaintext
    #     constraints: {
    #       encryption_context_subset: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #       encryption_context_equals: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     name: "GrantNameType",
    #   })
    #
    # @example Response structure
    #
    #   resp.grant_token #=> String
    #   resp.grant_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateGrant AWS API Documentation
    #
    # @overload create_grant(params = {})
    # @param [Hash] params ({})
    def create_grant(params = {}, options = {})
      req = build_request(:create_grant, params)
      req.send_request(options)
    end

    # Creates a unique customer managed [customer master key][1] (CMK) in
    # your AWS account and Region. You cannot use this operation to create a
    # CMK in a different AWS account.
    #
    # You can use the `CreateKey` operation to create symmetric or
    # asymmetric CMKs.
    #
    # * **Symmetric CMKs** contain a 256-bit symmetric key that never leaves
    #   AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can
    #   use a symmetric CMK to encrypt and decrypt small amounts of data,
    #   but they are typically used to generate [data keys][2] and [data
    #   keys pairs][3]. For details, see GenerateDataKey and
    #   GenerateDataKeyPair.
    #
    # * **Asymmetric CMKs** can contain an RSA key pair or an Elliptic Curve
    #   (ECC) key pair. The private key in an asymmetric CMK never leaves
    #   AWS KMS unencrypted. However, you can use the GetPublicKey operation
    #   to download the public key so it can be used outside of AWS KMS.
    #   CMKs with RSA key pairs can be used to encrypt or decrypt data or
    #   sign and verify messages (but not both). CMKs with ECC key pairs can
    #   be used only to sign and verify messages.
    #
    # For information about symmetric and asymmetric CMKs, see [Using
    # Symmetric and Asymmetric CMKs][4] in the *AWS Key Management Service
    # Developer Guide*.
    #
    # To create different types of CMKs, use the following guidance:
    #
    # Asymmetric CMKs
    #
    # : To create an asymmetric CMK, use the `CustomerMasterKeySpec`
    #   parameter to specify the type of key material in the CMK. Then, use
    #   the `KeyUsage` parameter to determine whether the CMK will be used
    #   to encrypt and decrypt or sign and verify. You can't change these
    #   properties after the CMK is created.
    #
    #
    #
    # Symmetric CMKs
    #
    # : When creating a symmetric CMK, you don't need to specify the
    #   `CustomerMasterKeySpec` or `KeyUsage` parameters. The default value
    #   for `CustomerMasterKeySpec`, `SYMMETRIC_DEFAULT`, and the default
    #   value for `KeyUsage`, `ENCRYPT_DECRYPT`, are the only valid values
    #   for symmetric CMKs.
    #
    #
    #
    # Imported Key Material
    #
    # : To import your own key material, begin by creating a symmetric CMK
    #   with no key material. To do this, use the `Origin` parameter of
    #   `CreateKey` with a value of `EXTERNAL`. Next, use
    #   GetParametersForImport operation to get a public key and import
    #   token, and use the public key to encrypt your key material. Then,
    #   use ImportKeyMaterial with your import token to import the key
    #   material. For step-by-step instructions, see [Importing Key
    #   Material][5] in the <i> <i>AWS Key Management Service Developer
    #   Guide</i> </i>. You cannot import the key material into an
    #   asymmetric CMK.
    #
    #
    #
    # Custom Key Stores
    #
    # : To create a symmetric CMK in a [custom key store][6], use the
    #   `CustomKeyStoreId` parameter to specify the custom key store. You
    #   must also use the `Origin` parameter with a value of `AWS_CLOUDHSM`.
    #   The AWS CloudHSM cluster that is associated with the custom key
    #   store must have at least two active HSMs in different Availability
    #   Zones in the AWS Region.
    #
    #   You cannot create an asymmetric CMK in a custom key store. For
    #   information about custom key stores in AWS KMS see [Using Custom Key
    #   Stores][6] in the <i> <i>AWS Key Management Service Developer
    #   Guide</i> </i>.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [String] :policy
    #   The key policy to attach to the CMK.
    #
    #   If you provide a key policy, it must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the key
    #     policy must allow the principal that is making the `CreateKey`
    #     request to make a subsequent PutKeyPolicy request on the CMK. This
    #     reduces the risk that the CMK becomes unmanageable. For more
    #     information, refer to the scenario in the [Default Key Policy][1]
    #     section of the <i> <i>AWS Key Management Service Developer Guide</i>
    #     </i>.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User Guide*.
    #
    #   If you do not provide a key policy, AWS KMS attaches a default key
    #   policy to the CMK. For more information, see [Default Key Policy][3]
    #   in the *AWS Key Management Service Developer Guide*.
    #
    #   The key policy size quota is 32 kilobytes (32768 bytes).
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default
    #
    # @option params [String] :description
    #   A description of the CMK.
    #
    #   Use a description that helps you decide whether the CMK is appropriate
    #   for a task.
    #
    # @option params [String] :key_usage
    #   Determines the [cryptographic operations][1] for which you can use the
    #   CMK. The default value is `ENCRYPT_DECRYPT`. This parameter is
    #   required only for asymmetric CMKs. You can't change the `KeyUsage`
    #   value after the CMK is created.
    #
    #   Select only one valid value.
    #
    #   * For symmetric CMKs, omit the parameter or specify `ENCRYPT_DECRYPT`.
    #
    #   * For asymmetric CMKs with RSA key material, specify `ENCRYPT_DECRYPT`
    #     or `SIGN_VERIFY`.
    #
    #   * For asymmetric CMKs with ECC key material, specify `SIGN_VERIFY`.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    #
    # @option params [String] :customer_master_key_spec
    #   Specifies the type of CMK to create. The default value,
    #   `SYMMETRIC_DEFAULT`, creates a CMK with a 256-bit symmetric key for
    #   encryption and decryption. For help choosing a key spec for your CMK,
    #   see [How to Choose Your CMK Configuration][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #   The `CustomerMasterKeySpec` determines whether the CMK contains a
    #   symmetric key or an asymmetric key pair. It also determines the
    #   encryption algorithms or signing algorithms that the CMK supports. You
    #   can't change the `CustomerMasterKeySpec` after the CMK is created. To
    #   further restrict the algorithms that can be used with the CMK, use a
    #   condition key in its key policy or IAM policy. For more information,
    #   see [kms:EncryptionAlgorithm][2] or [kms:Signing Algorithm][3] in the
    #   *AWS Key Management Service Developer Guide*.
    #
    #   [AWS services that are integrated with AWS KMS][4] use symmetric CMKs
    #   to protect your data. These services do not support asymmetric CMKs.
    #   For help determining whether a CMK is symmetric or asymmetric, see
    #   [Identifying Symmetric and Asymmetric CMKs][5] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #   AWS KMS supports the following key specs for CMKs:
    #
    #   * Symmetric key (default)
    #
    #     * `SYMMETRIC_DEFAULT` (AES-256-GCM)
    #
    #     ^
    #
    #   * Asymmetric RSA key pairs
    #
    #     * `RSA_2048`
    #
    #     * `RSA_3072`
    #
    #     * `RSA_4096`
    #
    #   * Asymmetric NIST-recommended elliptic curve key pairs
    #
    #     * `ECC_NIST_P256` (secp256r1)
    #
    #     * `ECC_NIST_P384` (secp384r1)
    #
    #     * `ECC_NIST_P521` (secp521r1)
    #
    #   * Other asymmetric elliptic curve key pairs
    #
    #     * `ECC_SECG_P256K1` (secp256k1), commonly used for cryptocurrencies.
    #
    #     ^
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symm-asymm-choose.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-encryption-algorithm
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-signing-algorithm
    #   [4]: http://aws.amazon.com/kms/features/#AWS_Service_Integration
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/find-symm-asymm.html
    #
    # @option params [String] :origin
    #   The source of the key material for the CMK. You cannot change the
    #   origin after you create the CMK. The default is `AWS_KMS`, which means
    #   AWS KMS creates the key material.
    #
    #   When the parameter value is `EXTERNAL`, AWS KMS creates a CMK without
    #   key material so that you can import key material from your existing
    #   key management infrastructure. For more information about importing
    #   key material into AWS KMS, see [Importing Key Material][1] in the *AWS
    #   Key Management Service Developer Guide*. This value is valid only for
    #   symmetric CMKs.
    #
    #   When the parameter value is `AWS_CLOUDHSM`, AWS KMS creates the CMK in
    #   an AWS KMS [custom key store][2] and creates its key material in the
    #   associated AWS CloudHSM cluster. You must also use the
    #   `CustomKeyStoreId` parameter to identify the custom key store. This
    #   value is valid only for symmetric CMKs.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [String] :custom_key_store_id
    #   Creates the CMK in the specified [custom key store][1] and the key
    #   material in its associated AWS CloudHSM cluster. To create a CMK in a
    #   custom key store, you must also specify the `Origin` parameter with a
    #   value of `AWS_CLOUDHSM`. The AWS CloudHSM cluster that is associated
    #   with the custom key store must have at least two active HSMs, each in
    #   a different Availability Zone in the Region.
    #
    #   This parameter is valid only for symmetric CMKs. You cannot create an
    #   asymmetric CMK in a custom key store.
    #
    #   To find the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #
    #   The response includes the custom key store ID and the ID of the AWS
    #   CloudHSM cluster.
    #
    #   This operation is part of the [Custom Key Store feature][1] feature in
    #   AWS KMS, which combines the convenience and extensive integration of
    #   AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the <i> <i>AWS Key Management Service Developer
    #   Guide</i> </i>.
    #
    #   Use this parameter only when you include a policy in the request and
    #   you intend to prevent the principal that is making the request from
    #   making a subsequent PutKeyPolicy request on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #
    # @option params [Array<Types::Tag>] :tags
    #   One or more tags. Each tag consists of a tag key and a tag value. Both
    #   the tag key and the tag value are required, but the tag value can be
    #   an empty (null) string.
    #
    #   When you add tags to an AWS resource, AWS generates a cost allocation
    #   report with usage and costs aggregated by tags. For information about
    #   adding, changing, deleting and listing tags for CMKs, see [Tagging
    #   Keys][1].
    #
    #   Use this parameter to tag the CMK when it is created. To add tags to
    #   an existing CMK, use the TagResource operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    #
    # @return [Types::CreateKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To create a customer master key (CMK)
    #
    #   # The following example creates a CMK.
    #
    #   resp = client.create_key({
    #     tags: [
    #       {
    #         tag_key: "CreatedBy", 
    #         tag_value: "ExampleUser", 
    #       }, 
    #     ], # One or more tags. Each tag consists of a tag key and a tag value.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the CMK created by this operation.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_key({
    #     policy: "PolicyType",
    #     description: "DescriptionType",
    #     key_usage: "SIGN_VERIFY", # accepts SIGN_VERIFY, ENCRYPT_DECRYPT
    #     customer_master_key_spec: "RSA_2048", # accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1, SYMMETRIC_DEFAULT
    #     origin: "AWS_KMS", # accepts AWS_KMS, EXTERNAL, AWS_CLOUDHSM
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     bypass_policy_lockout_safety_check: false,
    #     tags: [
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT"
    #   resp.key_metadata.key_state #=> String, one of "Enabled", "Disabled", "PendingDeletion", "PendingImport", "Unavailable"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #   resp.key_metadata.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT"
    #   resp.key_metadata.encryption_algorithms #=> Array
    #   resp.key_metadata.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #   resp.key_metadata.signing_algorithms #=> Array
    #   resp.key_metadata.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateKey AWS API Documentation
    #
    # @overload create_key(params = {})
    # @param [Hash] params ({})
    def create_key(params = {}, options = {})
      req = build_request(:create_key, params)
      req.send_request(options)
    end

    # Decrypts ciphertext that was encrypted by a AWS KMS customer master
    # key (CMK) using any of the following operations:
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # * GenerateDataKeyPairWithoutPlaintext
    #
    # You can use this operation to decrypt ciphertext that was encrypted
    # under a symmetric or asymmetric CMK. When the CMK is asymmetric, you
    # must specify the CMK and the encryption algorithm that was used to
    # encrypt the ciphertext. For information about symmetric and asymmetric
    # CMKs, see [Using Symmetric and Asymmetric CMKs][1] in the *AWS Key
    # Management Service Developer Guide*.
    #
    # The Decrypt operation also decrypts ciphertext that was encrypted
    # outside of AWS KMS by the public key in an AWS KMS asymmetric CMK.
    # However, it cannot decrypt ciphertext produced by other libraries,
    # such as the [AWS Encryption SDK][2] or [Amazon S3 client-side
    # encryption][3]. These libraries return a ciphertext format that is
    # incompatible with AWS KMS.
    #
    # If the ciphertext was encrypted under a symmetric CMK, you do not need
    # to specify the CMK or the encryption algorithm. AWS KMS can get this
    # information from metadata that it adds to the symmetric ciphertext
    # blob. However, if you prefer, you can specify the `KeyId` to ensure
    # that a particular CMK is used to decrypt the ciphertext. If you
    # specify a different CMK than the one used to encrypt the ciphertext,
    # the `Decrypt` operation fails.
    #
    # Whenever possible, use key policies to give users permission to call
    # the Decrypt operation on a particular CMK, instead of using IAM
    # policies. Otherwise, you might create an IAM user policy that gives
    # the user Decrypt permission on all CMKs. This user could decrypt
    # ciphertext that was encrypted by CMKs in other accounts if the key
    # policy for the cross-account CMK permits it. If you must use an IAM
    # policy for `Decrypt` permissions, limit the user to particular CMKs or
    # particular trusted accounts.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][4] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String, StringIO, File] :ciphertext_blob
    #   Ciphertext to be decrypted. The blob includes metadata.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context to use when decrypting the data. An
    #   encryption context is valid only for [cryptographic operations][1]
    #   with a symmetric CMK. The standard asymmetric encryption algorithms
    #   that AWS KMS uses do not support an encryption context.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][2] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @option params [String] :key_id
    #   Specifies the customer master key (CMK) that AWS KMS will use to
    #   decrypt the ciphertext. Enter a key ID of the CMK that was used to
    #   encrypt the ciphertext.
    #
    #   If you specify a `KeyId` value, the `Decrypt` operation succeeds only
    #   if the specified CMK was used to encrypt the ciphertext.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric CMK. Otherwise, AWS KMS uses the metadata that it
    #   adds to the ciphertext blob to determine which CMK was used to encrypt
    #   the ciphertext. However, you can use this parameter to ensure that a
    #   particular CMK (of any kind) is used to decrypt the ciphertext.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [String] :encryption_algorithm
    #   Specifies the encryption algorithm that will be used to decrypt the
    #   ciphertext. Specify the same algorithm that was used to encrypt the
    #   data. If you specify a different algorithm, the `Decrypt` operation
    #   fails.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric CMK. The default value, `SYMMETRIC_DEFAULT`,
    #   represents the only supported algorithm that is valid for symmetric
    #   CMKs.
    #
    # @return [Types::DecryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DecryptResponse#key_id #key_id} => String
    #   * {Types::DecryptResponse#plaintext #plaintext} => String
    #   * {Types::DecryptResponse#encryption_algorithm #encryption_algorithm} => String
    #
    #
    # @example Example: To decrypt data
    #
    #   # The following example decrypts data that was encrypted with a customer master key (CMK) in AWS KMS.
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the CMK that was used to decrypt the data.
    #     plaintext: "<binary data>", # The decrypted (plaintext) data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "data", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     key_id: "KeyIdType",
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.plaintext #=> String
    #   resp.encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Decrypt AWS API Documentation
    #
    # @overload decrypt(params = {})
    # @param [Hash] params ({})
    def decrypt(params = {}, options = {})
      req = build_request(:decrypt, params)
      req.send_request(options)
    end

    # Deletes the specified alias. You cannot perform this operation on an
    # alias in a different AWS account.
    #
    # Because an alias is not a property of a CMK, you can delete and change
    # the aliases of a CMK without affecting the CMK. Also, aliases do not
    # appear in the response from the DescribeKey operation. To get the
    # aliases of all CMKs, use the ListAliases operation.
    #
    # Each CMK can have multiple aliases. To change the alias of a CMK, use
    # DeleteAlias to delete the current alias and CreateAlias to create a
    # new alias. To associate an existing alias with a different customer
    # master key (CMK), call UpdateAlias.
    #
    # @option params [required, String] :alias_name
    #   The alias to be deleted. The alias name must begin with `alias/`
    #   followed by the alias name, such as `alias/ExampleAlias`.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete an alias
    #
    #   # The following example deletes the specified alias.
    #
    #   resp = client.delete_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to delete.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_alias({
    #     alias_name: "AliasNameType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteAlias AWS API Documentation
    #
    # @overload delete_alias(params = {})
    # @param [Hash] params ({})
    def delete_alias(params = {}, options = {})
      req = build_request(:delete_alias, params)
      req.send_request(options)
    end

    # Deletes a [custom key store][1]. This operation does not delete the
    # AWS CloudHSM cluster that is associated with the custom key store, or
    # affect any users or keys in the cluster.
    #
    # The custom key store that you delete cannot contain any AWS KMS
    # [customer master keys (CMKs)][2]. Before deleting the key store,
    # verify that you will never need to use any of the CMKs in the key
    # store for any [cryptographic operations][3]. Then, use
    # ScheduleKeyDeletion to delete the AWS KMS customer master keys (CMKs)
    # from the key store. When the scheduled waiting period expires, the
    # `ScheduleKeyDeletion` operation deletes the CMKs. Then it makes a best
    # effort to delete the key material from the associated cluster.
    # However, you might need to manually [delete the orphaned key
    # material][4] from the cluster and its backups.
    #
    # After all CMKs are deleted from AWS KMS, use DisconnectCustomKeyStore
    # to disconnect the key store from AWS KMS. Then, you can delete the
    # custom key store.
    #
    # Instead of deleting the custom key store, consider using
    # DisconnectCustomKeyStore to disconnect it from AWS KMS. While the key
    # store is disconnected, you cannot create or use the CMKs in the key
    # store. But, you do not need to delete CMKs and you can reconnect a
    # disconnected custom key store at any time.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to delete. To find the
    #   ID of a custom key store, use the DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteCustomKeyStore AWS API Documentation
    #
    # @overload delete_custom_key_store(params = {})
    # @param [Hash] params ({})
    def delete_custom_key_store(params = {}, options = {})
      req = build_request(:delete_custom_key_store, params)
      req.send_request(options)
    end

    # Deletes key material that you previously imported. This operation
    # makes the specified customer master key (CMK) unusable. For more
    # information about importing key material into AWS KMS, see [Importing
    # Key Material][1] in the *AWS Key Management Service Developer Guide*.
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # When the specified CMK is in the `PendingDeletion` state, this
    # operation does not change the CMK's state. Otherwise, it changes the
    # CMK's state to `PendingImport`.
    #
    # After you delete key material, you can use ImportKeyMaterial to
    # reimport the same key material into the CMK.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies the CMK from which you are deleting imported key material.
    #   The `Origin` of the CMK must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete imported key material
    #
    #   # The following example deletes the imported key material from the specified customer master key (CMK).
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose imported key material you are deleting. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteImportedKeyMaterial AWS API Documentation
    #
    # @overload delete_imported_key_material(params = {})
    # @param [Hash] params ({})
    def delete_imported_key_material(params = {}, options = {})
      req = build_request(:delete_imported_key_material, params)
      req.send_request(options)
    end

    # Gets information about [custom key stores][1] in the account and
    # region.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    # By default, this operation returns information about all custom key
    # stores in the account and region. To get only information about a
    # particular custom key store, use either the `CustomKeyStoreName` or
    # `CustomKeyStoreId` parameter (but not both).
    #
    # To determine whether the custom key store is connected to its AWS
    # CloudHSM cluster, use the `ConnectionState` element in the response.
    # If an attempt to connect the custom key store failed, the
    # `ConnectionState` value is `FAILED` and the `ConnectionErrorCode`
    # element in the response indicates the cause of the failure. For help
    # interpreting the `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # Custom key stores have a `DISCONNECTED` connection state if the key
    # store has never been connected or you use the DisconnectCustomKeyStore
    # operation to disconnect it. If your custom key store state is
    # `CONNECTED` but you are having trouble using it, make sure that its
    # associated AWS CloudHSM cluster is active and contains the minimum
    # number of HSMs required for the operation, if any.
    #
    # For help repairing your custom key store, see the [Troubleshooting
    # Custom Key Stores][2] topic in the *AWS Key Management Service
    # Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [String] :custom_key_store_id
    #   Gets only information about the specified custom key store. Enter the
    #   key store ID.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a particular
    #   custom key store, you can use either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [String] :custom_key_store_name
    #   Gets only information about the specified custom key store. Enter the
    #   friendly name of the custom key store.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a particular
    #   custom key store, you can use either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::DescribeCustomKeyStoresResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeCustomKeyStoresResponse#custom_key_stores #custom_key_stores} => Array&lt;Types::CustomKeyStoresListEntry&gt;
    #   * {Types::DescribeCustomKeyStoresResponse#next_marker #next_marker} => String
    #   * {Types::DescribeCustomKeyStoresResponse#truncated #truncated} => Boolean
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     custom_key_store_name: "CustomKeyStoreNameType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_stores #=> Array
    #   resp.custom_key_stores[0].custom_key_store_id #=> String
    #   resp.custom_key_stores[0].custom_key_store_name #=> String
    #   resp.custom_key_stores[0].cloud_hsm_cluster_id #=> String
    #   resp.custom_key_stores[0].trust_anchor_certificate #=> String
    #   resp.custom_key_stores[0].connection_state #=> String, one of "CONNECTED", "CONNECTING", "FAILED", "DISCONNECTED", "DISCONNECTING"
    #   resp.custom_key_stores[0].connection_error_code #=> String, one of "INVALID_CREDENTIALS", "CLUSTER_NOT_FOUND", "NETWORK_ERRORS", "INTERNAL_ERROR", "INSUFFICIENT_CLOUDHSM_HSMS", "USER_LOCKED_OUT", "USER_NOT_FOUND", "USER_LOGGED_IN", "SUBNET_NOT_FOUND"
    #   resp.custom_key_stores[0].creation_date #=> Time
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeCustomKeyStores AWS API Documentation
    #
    # @overload describe_custom_key_stores(params = {})
    # @param [Hash] params ({})
    def describe_custom_key_stores(params = {}, options = {})
      req = build_request(:describe_custom_key_stores, params)
      req.send_request(options)
    end

    # Provides detailed information about a customer master key (CMK). You
    # can run `DescribeKey` on a [customer managed CMK][1] or an [AWS
    # managed CMK][2].
    #
    # This detailed information includes the key ARN, creation date (and
    # deletion date, if applicable), the key state, and the origin and
    # expiration date (if any) of the key material. For CMKs in custom key
    # stores, it includes information about the custom key store, such as
    # the key store ID and the AWS CloudHSM cluster ID. It includes fields,
    # like `KeySpec`, that help you distinguish symmetric from asymmetric
    # CMKs. It also provides information that is particularly important to
    # asymmetric CMKs, such as the key usage (encryption or signing) and the
    # encryption algorithms or signing algorithms that the CMK supports.
    #
    # `DescribeKey` does not return the following information:
    #
    # * Aliases associated with the CMK. To get this information, use
    #   ListAliases.
    #
    # * Whether automatic key rotation is enabled on the CMK. To get this
    #   information, use GetKeyRotationStatus. Also, some key states prevent
    #   a CMK from being automatically rotated. For details, see [How
    #   Automatic Key Rotation Works][3] in *AWS Key Management Service
    #   Developer Guide*.
    #
    # * Tags on the CMK. To get this information, use ListResourceTags.
    #
    # * Key policies and grants on the CMK. To get this information, use
    #   GetKeyPolicy and ListGrants.
    #
    # If you call the `DescribeKey` operation on a *predefined AWS alias*,
    # that is, an AWS alias with no key ID, AWS KMS creates an [AWS managed
    # CMK][4]. Then, it associates the alias with the new CMK, and returns
    # the `KeyId` and `Arn` of the new CMK in the response.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN or alias ARN in the value of the KeyId parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #
    # @option params [required, String] :key_id
    #   Describes the specified customer master key (CMK).
    #
    #   If you specify a predefined AWS alias (an AWS alias with no key ID),
    #   KMS associates the alias with an [AWS managed CMK][1] and returns its
    #   `KeyId` and `Arn` in the response.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::DescribeKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To obtain information about a customer master key (CMK)
    #
    #   # The following example returns information (metadata) about the specified CMK.
    #
    #   resp = client.describe_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK that you want information about. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the specified CMK.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_key({
    #     key_id: "KeyIdType", # required
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT"
    #   resp.key_metadata.key_state #=> String, one of "Enabled", "Disabled", "PendingDeletion", "PendingImport", "Unavailable"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #   resp.key_metadata.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT"
    #   resp.key_metadata.encryption_algorithms #=> Array
    #   resp.key_metadata.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #   resp.key_metadata.signing_algorithms #=> Array
    #   resp.key_metadata.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeKey AWS API Documentation
    #
    # @overload describe_key(params = {})
    # @param [Hash] params ({})
    def describe_key(params = {}, options = {})
      req = build_request(:describe_key, params)
      req.send_request(options)
    end

    # Sets the state of a customer master key (CMK) to disabled, thereby
    # preventing its use for [cryptographic operations][1]. You cannot
    # perform this operation on a CMK in a different AWS account.
    #
    # For more information about how key state affects the use of a CMK, see
    # [How Key State Affects the Use of a Customer Master Key][2] in the <i>
    # <i>AWS Key Management Service Developer Guide</i> </i>.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable a customer master key (CMK)
    #
    #   # The following example disables the specified CMK.
    #
    #   resp = client.disable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to disable. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKey AWS API Documentation
    #
    # @overload disable_key(params = {})
    # @param [Hash] params ({})
    def disable_key(params = {}, options = {})
      req = build_request(:disable_key, params)
      req.send_request(options)
    end

    # Disables [automatic rotation of the key material][1] for the specified
    # symmetric customer master key (CMK).
    #
    # You cannot enable automatic rotation of asymmetric CMKs, CMKs with
    # imported key material, or CMKs in a [custom key store][2]. You cannot
    # perform this operation on a CMK in a different AWS account.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][3] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies a symmetric customer master key (CMK). You cannot enable
    #   automatic rotation of [asymmetric CMKs][1], CMKs with [imported key
    #   material][2], or CMKs in a [custom key store][3].
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html#asymmetric-cmks
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable automatic rotation of key material
    #
    #   # The following example disables automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material will no longer be rotated. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKeyRotation AWS API Documentation
    #
    # @overload disable_key_rotation(params = {})
    # @param [Hash] params ({})
    def disable_key_rotation(params = {}, options = {})
      req = build_request(:disable_key_rotation, params)
      req.send_request(options)
    end

    # Disconnects the [custom key store][1] from its associated AWS CloudHSM
    # cluster. While a custom key store is disconnected, you can manage the
    # custom key store and its customer master keys (CMKs), but you cannot
    # create or use CMKs in the custom key store. You can reconnect the
    # custom key store at any time.
    #
    # <note markdown="1"> While a custom key store is disconnected, all attempts to create
    # customer master keys (CMKs) in the custom key store or to use existing
    # CMKs in [cryptographic operations][2] will fail. This action can
    # prevent users from storing and accessing sensitive data.
    #
    #  </note>
    #
    #
    #
    # To find the connection state of a custom key store, use the
    # DescribeCustomKeyStores operation. To reconnect a custom key store,
    # use the ConnectCustomKeyStore operation.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to disconnect. To find
    #   the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disconnect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisconnectCustomKeyStore AWS API Documentation
    #
    # @overload disconnect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def disconnect_custom_key_store(params = {}, options = {})
      req = build_request(:disconnect_custom_key_store, params)
      req.send_request(options)
    end

    # Sets the key state of a customer master key (CMK) to enabled. This
    # allows you to use the CMK for [cryptographic operations][1]. You
    # cannot perform this operation on a CMK in a different AWS account.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable a customer master key (CMK)
    #
    #   # The following example enables the specified CMK.
    #
    #   resp = client.enable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to enable. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKey AWS API Documentation
    #
    # @overload enable_key(params = {})
    # @param [Hash] params ({})
    def enable_key(params = {}, options = {})
      req = build_request(:enable_key, params)
      req.send_request(options)
    end

    # Enables [automatic rotation of the key material][1] for the specified
    # symmetric customer master key (CMK). You cannot perform this operation
    # on a CMK in a different AWS account.
    #
    # You cannot enable automatic rotation of asymmetric CMKs, CMKs with
    # imported key material, or CMKs in a [custom key store][2].
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][3] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies a symmetric customer master key (CMK). You cannot enable
    #   automatic rotation of asymmetric CMKs, CMKs with imported key
    #   material, or CMKs in a [custom key store][1].
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable automatic rotation of key material
    #
    #   # The following example enables automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material will be rotated annually. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKeyRotation AWS API Documentation
    #
    # @overload enable_key_rotation(params = {})
    # @param [Hash] params ({})
    def enable_key_rotation(params = {}, options = {})
      req = build_request(:enable_key_rotation, params)
      req.send_request(options)
    end

    # Encrypts plaintext into ciphertext by using a customer master key
    # (CMK). The `Encrypt` operation has two primary use cases:
    #
    # * You can encrypt small amounts of arbitrary data, such as a personal
    #   identifier or database password, or other sensitive information.
    #
    # * You can use the `Encrypt` operation to move encrypted data from one
    #   AWS Region to another. For example, in Region A, generate a data key
    #   and use the plaintext key to encrypt your data. Then, in Region A,
    #   use the `Encrypt` operation to encrypt the plaintext data key under
    #   a CMK in Region B. Now, you can move the encrypted data and the
    #   encrypted data key to Region B. When necessary, you can decrypt the
    #   encrypted data key and the encrypted data entirely within in Region
    #   B.
    #
    # You don't need to use the `Encrypt` operation to encrypt a data key.
    # The GenerateDataKey and GenerateDataKeyPair operations return a
    # plaintext data key and an encrypted copy of that data key.
    #
    # When you encrypt data, you must specify a symmetric or asymmetric CMK
    # to use in the encryption operation. The CMK must have a `KeyUsage`
    # value of `ENCRYPT_DECRYPT.` To find the `KeyUsage` of a CMK, use the
    # DescribeKey operation.
    #
    # If you use a symmetric CMK, you can use an encryption context to add
    # additional security to your encryption operation. If you specify an
    # `EncryptionContext` when encrypting data, you must specify the same
    # encryption context (a case-sensitive exact match) when decrypting the
    # data. Otherwise, the request to decrypt fails with an
    # `InvalidCiphertextException`. For more information, see [Encryption
    # Context][1] in the *AWS Key Management Service Developer Guide*.
    #
    # If you specify an asymmetric CMK, you must also specify the encryption
    # algorithm. The algorithm must be compatible with the CMK type.
    #
    # When you use an asymmetric CMK to encrypt or reencrypt data, be sure
    # to record the CMK and encryption algorithm that you choose. You will
    # be required to provide the same CMK and encryption algorithm when you
    # decrypt the data. If the CMK and algorithm do not match the values
    # used to encrypt the data, the decrypt operation fails.
    #
    #  You are not required to supply the CMK ID and encryption algorithm
    # when you decrypt with symmetric CMKs because AWS KMS stores this
    # information in the ciphertext blob. AWS KMS cannot store metadata in
    # ciphertext generated with asymmetric keys. The standard format for
    # asymmetric key ciphertext does not include configurable fields.
    #
    # The maximum size of the data that you can encrypt varies with the type
    # of CMK and the encryption algorithm that you choose.
    #
    # * Symmetric CMKs
    #
    #   * `SYMMETRIC_DEFAULT`\: 4096 bytes
    #
    #   ^
    #
    # * `RSA_2048`
    #
    #   * `RSAES_OAEP_SHA_1`\: 214 bytes
    #
    #   * `RSAES_OAEP_SHA_256`\: 190 bytes
    #
    # * `RSA_3072`
    #
    #   * `RSAES_OAEP_SHA_1`\: 342 bytes
    #
    #   * `RSAES_OAEP_SHA_256`\: 318 bytes
    #
    # * `RSA_4096`
    #
    #   * `RSAES_OAEP_SHA_1`\: 470 bytes
    #
    #   * `RSAES_OAEP_SHA_256`\: 446 bytes
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN or alias ARN in the value of the KeyId parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :plaintext
    #   Data to be encrypted.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used to encrypt the
    #   data. An encryption context is valid only for [cryptographic
    #   operations][1] with a symmetric CMK. The standard asymmetric
    #   encryption algorithms that AWS KMS uses do not support an encryption
    #   context.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][2] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @option params [String] :encryption_algorithm
    #   Specifies the encryption algorithm that AWS KMS will use to encrypt
    #   the plaintext message. The algorithm must be compatible with the CMK
    #   that you specify.
    #
    #   This parameter is required only for asymmetric CMKs. The default
    #   value, `SYMMETRIC_DEFAULT`, is the algorithm used for symmetric CMKs.
    #   If you are using an asymmetric CMK, we recommend
    #   RSAES\_OAEP\_SHA\_256.
    #
    # @return [Types::EncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::EncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::EncryptResponse#key_id #key_id} => String
    #   * {Types::EncryptResponse#encryption_algorithm #encryption_algorithm} => String
    #
    #
    # @example Example: To encrypt data
    #
    #   # The following example encrypts data with the specified customer master key (CMK).
    #
    #   resp = client.encrypt({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to use for encryption. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     plaintext: "<binary data>", # The data to encrypt.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.encrypt({
    #     key_id: "KeyIdType", # required
    #     plaintext: "data", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #   resp.encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Encrypt AWS API Documentation
    #
    # @overload encrypt(params = {})
    # @param [Hash] params ({})
    def encrypt(params = {}, options = {})
      req = build_request(:encrypt, params)
      req.send_request(options)
    end

    # Generates a unique symmetric data key for client-side encryption. This
    # operation returns a plaintext copy of the data key and a copy that is
    # encrypted under a customer master key (CMK) that you specify. You can
    # use the plaintext key to encrypt your data outside of AWS KMS and
    # store the encrypted data key with the encrypted data.
    #
    # `GenerateDataKey` returns a unique data key for each request. The
    # bytes in the plaintext key are not related to the caller or the CMK.
    #
    # To generate a data key, specify the symmetric CMK that will be used to
    # encrypt the data key. You cannot use an asymmetric CMK to generate
    # data keys. To get the type of your CMK, use the DescribeKey operation.
    # You must also specify the length of the data key. Use either the
    # `KeySpec` or `NumberOfBytes` parameters (but not both). For 128-bit
    # and 256-bit data keys, use the `KeySpec` parameter.
    #
    # To get only an encrypted copy of the data key, use
    # GenerateDataKeyWithoutPlaintext. To generate an asymmetric data key
    # pair, use the GenerateDataKeyPair or
    # GenerateDataKeyPairWithoutPlaintext operation. To get a
    # cryptographically secure random byte string, use GenerateRandom.
    #
    # You can use the optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    # **How to use your data key**
    #
    # We recommend that you use the following pattern to encrypt data
    # locally in your application. You can write your own code or use a
    # client-side encryption library, such as the [AWS Encryption SDK][3],
    # the [Amazon DynamoDB Encryption Client][4], or [Amazon S3 client-side
    # encryption][5] to do these tasks for you.
    #
    # To encrypt data outside of AWS KMS:
    #
    # 1.  Use the `GenerateDataKey` operation to get a data key.
    #
    # 2.  Use the plaintext data key (in the `Plaintext` field of the
    #     response) to encrypt your data outside of AWS KMS. Then erase the
    #     plaintext data key from memory.
    #
    # 3.  Store the encrypted data key (in the `CiphertextBlob` field of the
    #     response) with the encrypted data.
    #
    # To decrypt data outside of AWS KMS:
    #
    # 1.  Use the Decrypt operation to decrypt the encrypted data key. The
    #     operation returns a plaintext copy of the data key.
    #
    # 2.  Use the plaintext data key to decrypt data outside of AWS KMS,
    #     then erase the plaintext data key from memory.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [4]: https://docs.aws.amazon.com/dynamodb-encryption-client/latest/devguide/
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    #
    # @option params [required, String] :key_id
    #   Identifies the symmetric CMK that encrypts the data key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   data key.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Integer] :number_of_bytes
    #   Specifies the length of the data key in bytes. For example, use the
    #   value 64 to generate a 512-bit data key (64 bytes is 512 bits). For
    #   128-bit (16-byte) and 256-bit (32-byte) data keys, use the `KeySpec`
    #   parameter.
    #
    #   You must specify either the `KeySpec` or the `NumberOfBytes` parameter
    #   (but not both) in every `GenerateDataKey` request.
    #
    # @option params [String] :key_spec
    #   Specifies the length of the data key. Use `AES_128` to generate a
    #   128-bit symmetric key, or `AES_256` to generate a 256-bit symmetric
    #   key.
    #
    #   You must specify either the `KeySpec` or the `NumberOfBytes` parameter
    #   (but not both) in every `GenerateDataKey` request.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyResponse#plaintext #plaintext} => String
    #   * {Types::GenerateDataKeyResponse#key_id #key_id} => String
    #
    #
    # @example Example: To generate a data key
    #
    #   # The following example generates a 256-bit symmetric data encryption key (data key) in two formats. One is the
    #   # unencrypted (plainext) data key, and the other is the data key encrypted with the specified customer master key (CMK).
    #
    #   resp = client.generate_data_key({
    #     key_id: "alias/ExampleAlias", # The identifier of the CMK to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data key.
    #     plaintext: "<binary data>", # The unencrypted (plaintext) data key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     number_of_bytes: 1,
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.plaintext #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKey AWS API Documentation
    #
    # @overload generate_data_key(params = {})
    # @param [Hash] params ({})
    def generate_data_key(params = {}, options = {})
      req = build_request(:generate_data_key, params)
      req.send_request(options)
    end

    # Generates a unique asymmetric data key pair. The `GenerateDataKeyPair`
    # operation returns a plaintext public key, a plaintext private key, and
    # a copy of the private key that is encrypted under the symmetric CMK
    # you specify. You can use the data key pair to perform asymmetric
    # cryptography outside of AWS KMS.
    #
    # `GenerateDataKeyPair` returns a unique data key pair for each request.
    # The bytes in the keys are not related to the caller or the CMK that is
    # used to encrypt the private key.
    #
    # You can use the public key that `GenerateDataKeyPair` returns to
    # encrypt data or verify a signature outside of AWS KMS. Then, store the
    # encrypted private key with the data. When you are ready to decrypt
    # data or sign a message, you can use the Decrypt operation to decrypt
    # the encrypted private key.
    #
    # To generate a data key pair, you must specify a symmetric customer
    # master key (CMK) to encrypt the private key in a data key pair. You
    # cannot use an asymmetric CMK or a CMK in a custom key store. To get
    # the type and origin of your CMK, use the DescribeKey operation.
    #
    # If you are using the data key pair to encrypt data, or for any
    # operation where you don't immediately need a private key, consider
    # using the GenerateDataKeyPairWithoutPlaintext operation.
    # `GenerateDataKeyPairWithoutPlaintext` returns a plaintext public key
    # and an encrypted private key, but omits the plaintext private key that
    # you need only to decrypt ciphertext or sign a message. Later, when you
    # need to decrypt the data or sign a message, use the Decrypt operation
    # to decrypt the encrypted private key in the data key pair.
    #
    # You can use the optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   private key in the data key pair.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [required, String] :key_id
    #   Specifies the symmetric CMK that encrypts the private key in the data
    #   key pair. You cannot specify an asymmetric CMK or a CMK in a custom
    #   key store. To get the type and origin of your CMK, use the DescribeKey
    #   operation.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :key_pair_spec
    #   Determines the type of data key pair that is generated.
    #
    #   The AWS KMS rule that restricts the use of asymmetric RSA CMKs to
    #   encrypt and decrypt or to sign and verify (but not both), and the rule
    #   that permits you to use ECC CMKs only to sign and verify, are not
    #   effective outside of AWS KMS.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyPairResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyPairResponse#private_key_ciphertext_blob #private_key_ciphertext_blob} => String
    #   * {Types::GenerateDataKeyPairResponse#private_key_plaintext #private_key_plaintext} => String
    #   * {Types::GenerateDataKeyPairResponse#public_key #public_key} => String
    #   * {Types::GenerateDataKeyPairResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyPairResponse#key_pair_spec #key_pair_spec} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_pair({
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_id: "KeyIdType", # required
    #     key_pair_spec: "RSA_2048", # required, accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.private_key_ciphertext_blob #=> String
    #   resp.private_key_plaintext #=> String
    #   resp.public_key #=> String
    #   resp.key_id #=> String
    #   resp.key_pair_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyPair AWS API Documentation
    #
    # @overload generate_data_key_pair(params = {})
    # @param [Hash] params ({})
    def generate_data_key_pair(params = {}, options = {})
      req = build_request(:generate_data_key_pair, params)
      req.send_request(options)
    end

    # Generates a unique asymmetric data key pair. The
    # `GenerateDataKeyPairWithoutPlaintext` operation returns a plaintext
    # public key and a copy of the private key that is encrypted under the
    # symmetric CMK you specify. Unlike GenerateDataKeyPair, this operation
    # does not return a plaintext private key.
    #
    # To generate a data key pair, you must specify a symmetric customer
    # master key (CMK) to encrypt the private key in the data key pair. You
    # cannot use an asymmetric CMK or a CMK in a custom key store. To get
    # the type and origin of your CMK, use the `KeySpec` field in the
    # DescribeKey response.
    #
    # You can use the public key that `GenerateDataKeyPairWithoutPlaintext`
    # returns to encrypt data or verify a signature outside of AWS KMS.
    # Then, store the encrypted private key with the data. When you are
    # ready to decrypt data or sign a message, you can use the Decrypt
    # operation to decrypt the encrypted private key.
    #
    # `GenerateDataKeyPairWithoutPlaintext` returns a unique data key pair
    # for each request. The bytes in the key are not related to the caller
    # or CMK that is used to encrypt the private key.
    #
    # You can use the optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   private key in the data key pair.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [required, String] :key_id
    #   Specifies the CMK that encrypts the private key in the data key pair.
    #   You must specify a symmetric CMK. You cannot use an asymmetric CMK or
    #   a CMK in a custom key store. To get the type and origin of your CMK,
    #   use the DescribeKey operation.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :key_pair_spec
    #   Determines the type of data key pair that is generated.
    #
    #   The AWS KMS rule that restricts the use of asymmetric RSA CMKs to
    #   encrypt and decrypt or to sign and verify (but not both), and the rule
    #   that permits you to use ECC CMKs only to sign and verify, are not
    #   effective outside of AWS KMS.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyPairWithoutPlaintextResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#private_key_ciphertext_blob #private_key_ciphertext_blob} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#public_key #public_key} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#key_pair_spec #key_pair_spec} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_pair_without_plaintext({
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_id: "KeyIdType", # required
    #     key_pair_spec: "RSA_2048", # required, accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.private_key_ciphertext_blob #=> String
    #   resp.public_key #=> String
    #   resp.key_id #=> String
    #   resp.key_pair_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyPairWithoutPlaintext AWS API Documentation
    #
    # @overload generate_data_key_pair_without_plaintext(params = {})
    # @param [Hash] params ({})
    def generate_data_key_pair_without_plaintext(params = {}, options = {})
      req = build_request(:generate_data_key_pair_without_plaintext, params)
      req.send_request(options)
    end

    # Generates a unique symmetric data key. This operation returns a data
    # key that is encrypted under a customer master key (CMK) that you
    # specify. To request an asymmetric data key pair, use the
    # GenerateDataKeyPair or GenerateDataKeyPairWithoutPlaintext operations.
    #
    # `GenerateDataKeyWithoutPlaintext` is identical to the GenerateDataKey
    # operation except that returns only the encrypted copy of the data key.
    # This operation is useful for systems that need to encrypt data at some
    # point, but not immediately. When you need to encrypt the data, you
    # call the Decrypt operation on the encrypted copy of the key.
    #
    # It's also useful in distributed systems with different levels of
    # trust. For example, you might store encrypted data in containers. One
    # component of your system creates new containers and stores an
    # encrypted data key with each container. Then, a different component
    # puts the data into the containers. That component first decrypts the
    # data key, uses the plaintext data key to encrypt data, puts the
    # encrypted data into the container, and then destroys the plaintext
    # data key. In this system, the component that creates the containers
    # never sees the plaintext data key.
    #
    # `GenerateDataKeyWithoutPlaintext` returns a unique data key for each
    # request. The bytes in the keys are not related to the caller or CMK
    # that is used to encrypt the private key.
    #
    # To generate a data key, you must specify the symmetric customer master
    # key (CMK) that is used to encrypt the data key. You cannot use an
    # asymmetric CMK to generate a data key. To get the type of your CMK,
    # use the DescribeKey operation.
    #
    # If the operation succeeds, you will find the encrypted copy of the
    # data key in the `CiphertextBlob` field.
    #
    # You can use the optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the symmetric customer master key (CMK) that
    #   encrypts the data key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   data key.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [String] :key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64 to
    #   generate a 512-bit data key (64 bytes is 512 bits). For common key
    #   lengths (128-bit and 256-bit symmetric keys), we recommend that you
    #   use the `KeySpec` field instead of this one.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyWithoutPlaintextResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#key_id #key_id} => String
    #
    #
    # @example Example: To generate an encrypted data key
    #
    #   # The following example generates an encrypted copy of a 256-bit symmetric data encryption key (data key). The data key is
    #   # encrypted with the specified customer master key (CMK).
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "alias/ExampleAlias", # The identifier of the CMK to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     number_of_bytes: 1,
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyWithoutPlaintext AWS API Documentation
    #
    # @overload generate_data_key_without_plaintext(params = {})
    # @param [Hash] params ({})
    def generate_data_key_without_plaintext(params = {}, options = {})
      req = build_request(:generate_data_key_without_plaintext, params)
      req.send_request(options)
    end

    # Returns a random byte string that is cryptographically secure.
    #
    # By default, the random byte string is generated in AWS KMS. To
    # generate the byte string in the AWS CloudHSM cluster that is
    # associated with a [custom key store][1], specify the custom key store
    # ID.
    #
    # For more information about entropy and random number generation, see
    # the [AWS Key Management Service Cryptographic Details][2] whitepaper.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the byte string.
    #
    # @option params [String] :custom_key_store_id
    #   Generates the random byte string in the AWS CloudHSM cluster that is
    #   associated with the specified [custom key store][1]. To find the ID of
    #   a custom key store, use the DescribeCustomKeyStores operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @return [Types::GenerateRandomResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateRandomResponse#plaintext #plaintext} => String
    #
    #
    # @example Example: To generate random data
    #
    #   # The following example uses AWS KMS to generate 32 bytes of random data.
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 32, # The length of the random data, specified in number of bytes.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     plaintext: "<binary data>", # The random data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 1,
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.plaintext #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateRandom AWS API Documentation
    #
    # @overload generate_random(params = {})
    # @param [Hash] params ({})
    def generate_random(params = {}, options = {})
      req = build_request(:generate_random, params)
      req.send_request(options)
    end

    # Gets a key policy attached to the specified customer master key (CMK).
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :policy_name
    #   Specifies the name of the key policy. The only valid name is
    #   `default`. To get the names of key policies, use ListKeyPolicies.
    #
    # @return [Types::GetKeyPolicyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyPolicyResponse#policy #policy} => String
    #
    #
    # @example Example: To retrieve a key policy
    #
    #   # The following example retrieves the key policy for the specified customer master key (CMK).
    #
    #   resp = client.get_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key policy you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     policy_name: "default", # The name of the key policy to retrieve.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy: "{\n  \"Version\" : \"2012-10-17\",\n  \"Id\" : \"key-default-1\",\n  \"Statement\" : [ {\n    \"Sid\" : \"Enable IAM User Permissions\",\n    \"Effect\" : \"Allow\",\n    \"Principal\" : {\n      \"AWS\" : \"arn:aws:iam::111122223333:root\"\n    },\n    \"Action\" : \"kms:*\",\n    \"Resource\" : \"*\"\n  } ]\n}", # The key policy document.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.policy #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyPolicy AWS API Documentation
    #
    # @overload get_key_policy(params = {})
    # @param [Hash] params ({})
    def get_key_policy(params = {}, options = {})
      req = build_request(:get_key_policy, params)
      req.send_request(options)
    end

    # Gets a Boolean value that indicates whether [automatic rotation of the
    # key material][1] is enabled for the specified customer master key
    # (CMK).
    #
    # You cannot enable automatic rotation of asymmetric CMKs, CMKs with
    # imported key material, or CMKs in a [custom key store][2]. The key
    # rotation status for these CMKs is always `false`.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][3] in the *AWS Key Management Service Developer Guide*.
    #
    # * Disabled: The key rotation status does not change when you disable a
    #   CMK. However, while the CMK is disabled, AWS KMS does not rotate the
    #   backing key.
    #
    # * Pending deletion: While a CMK is pending deletion, its key rotation
    #   status is `false` and AWS KMS does not rotate the backing key. If
    #   you cancel the deletion, the original key rotation status is
    #   restored.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::GetKeyRotationStatusResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyRotationStatusResponse#key_rotation_enabled #key_rotation_enabled} => Boolean
    #
    #
    # @example Example: To retrieve the rotation status for a customer master key (CMK)
    #
    #   # The following example retrieves the status of automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material rotation status you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_rotation_enabled: true, # A boolean that indicates the key material rotation status. Returns true when automatic annual rotation of the key material is enabled, or false when it is not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_rotation_enabled #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyRotationStatus AWS API Documentation
    #
    # @overload get_key_rotation_status(params = {})
    # @param [Hash] params ({})
    def get_key_rotation_status(params = {}, options = {})
      req = build_request(:get_key_rotation_status, params)
      req.send_request(options)
    end

    # Returns the items you need to import key material into a symmetric,
    # customer managed customer master key (CMK). For more information about
    # importing key material into AWS KMS, see [Importing Key Material][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    # This operation returns a public key and an import token. Use the
    # public key to encrypt the symmetric key material. Store the import
    # token to send with a subsequent ImportKeyMaterial request.
    #
    # You must specify the key ID of the symmetric CMK into which you will
    # import key material. This CMK's `Origin` must be `EXTERNAL`. You must
    # also specify the wrapping algorithm and type of wrapping key (public
    # key) that you will use to encrypt the key material. You cannot perform
    # this operation on an asymmetric CMK or on any CMK in a different AWS
    # account.
    #
    # To import key material, you must use the public key and import token
    # from the same response. These items are valid for 24 hours. The
    # expiration date and time appear in the `GetParametersForImport`
    # response. You cannot use an expired token in an ImportKeyMaterial
    # request. If your key and token expire, send another
    # `GetParametersForImport` request.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the symmetric CMK into which you will import key
    #   material. The `Origin` of the CMK must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :wrapping_algorithm
    #   The algorithm you will use to encrypt the key material before
    #   importing it with ImportKeyMaterial. For more information, see
    #   [Encrypt the Key Material][1] in the *AWS Key Management Service
    #   Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-encrypt-key-material.html
    #
    # @option params [required, String] :wrapping_key_spec
    #   The type of wrapping key (public key) to return in the response. Only
    #   2048-bit RSA public keys are supported.
    #
    # @return [Types::GetParametersForImportResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetParametersForImportResponse#key_id #key_id} => String
    #   * {Types::GetParametersForImportResponse#import_token #import_token} => String
    #   * {Types::GetParametersForImportResponse#public_key #public_key} => String
    #   * {Types::GetParametersForImportResponse#parameters_valid_to #parameters_valid_to} => Time
    #
    #
    # @example Example: To retrieve the public key and import token for a customer master key (CMK)
    #
    #   # The following example retrieves the public key and import token for the specified CMK.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK for which to retrieve the public key and import token. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     wrapping_algorithm: "RSAES_OAEP_SHA_1", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_2048", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK for which you are retrieving the public key and import token. This is the same CMK specified in the request.
    #     parameters_valid_to: Time.parse("2016-12-01T14:52:17-08:00"), # The time at which the import token and public key are no longer valid.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "KeyIdType", # required
    #     wrapping_algorithm: "RSAES_PKCS1_V1_5", # required, accepts RSAES_PKCS1_V1_5, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #     wrapping_key_spec: "RSA_2048", # required, accepts RSA_2048
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.import_token #=> String
    #   resp.public_key #=> String
    #   resp.parameters_valid_to #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetParametersForImport AWS API Documentation
    #
    # @overload get_parameters_for_import(params = {})
    # @param [Hash] params ({})
    def get_parameters_for_import(params = {}, options = {})
      req = build_request(:get_parameters_for_import, params)
      req.send_request(options)
    end

    # Returns the public key of an asymmetric CMK. Unlike the private key of
    # a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with
    # `kms:GetPublicKey` permission can download the public key of an
    # asymmetric CMK. You can share the public key to allow others to
    # encrypt messages and verify signatures outside of AWS KMS. For
    # information about symmetric and asymmetric CMKs, see [Using Symmetric
    # and Asymmetric CMKs][1] in the *AWS Key Management Service Developer
    # Guide*.
    #
    # You do not need to download the public key. Instead, you can use the
    # public key within AWS KMS by calling the Encrypt, ReEncrypt, or Verify
    # operations with the identifier of an asymmetric CMK. When you use the
    # public key within AWS KMS, you benefit from the authentication,
    # authorization, and logging that are part of every AWS KMS operation.
    # You also reduce of risk of encrypting data that cannot be decrypted.
    # These features are not effective outside of AWS KMS. For details, see
    # [Special Considerations for Downloading Public Keys][2].
    #
    # To help you use the public key safely outside of AWS KMS,
    # `GetPublicKey` returns important information about the public key in
    # the response, including:
    #
    # * [CustomerMasterKeySpec][3]\: The type of key material in the public
    #   key, such as `RSA_4096` or `ECC_NIST_P521`.
    #
    # * [KeyUsage][4]\: Whether the key is used for encryption or signing.
    #
    # * [EncryptionAlgorithms][5] or [SigningAlgorithms][6]\: A list of the
    #   encryption algorithms or the signing algorithms for the key.
    #
    # Although AWS KMS cannot enforce these restrictions on external
    # operations, it is crucial that you use this information to prevent the
    # public key from being used improperly. For example, you can prevent a
    # public signing key from being used encrypt data, or prevent a public
    # key from being used with an encryption algorithm that is not supported
    # by AWS KMS. You can also avoid errors, such as using the wrong signing
    # algorithm in a verification operation.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][7] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations
    # [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec
    # [4]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage
    # [5]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms
    # [6]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies the asymmetric CMK that includes the public key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GetPublicKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetPublicKeyResponse#key_id #key_id} => String
    #   * {Types::GetPublicKeyResponse#public_key #public_key} => String
    #   * {Types::GetPublicKeyResponse#customer_master_key_spec #customer_master_key_spec} => String
    #   * {Types::GetPublicKeyResponse#key_usage #key_usage} => String
    #   * {Types::GetPublicKeyResponse#encryption_algorithms #encryption_algorithms} => Array&lt;String&gt;
    #   * {Types::GetPublicKeyResponse#signing_algorithms #signing_algorithms} => Array&lt;String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_public_key({
    #     key_id: "KeyIdType", # required
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.public_key #=> String
    #   resp.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT"
    #   resp.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT"
    #   resp.encryption_algorithms #=> Array
    #   resp.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #   resp.signing_algorithms #=> Array
    #   resp.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetPublicKey AWS API Documentation
    #
    # @overload get_public_key(params = {})
    # @param [Hash] params ({})
    def get_public_key(params = {}, options = {})
      req = build_request(:get_public_key, params)
      req.send_request(options)
    end

    # Imports key material into an existing symmetric AWS KMS customer
    # master key (CMK) that was created without key material. After you
    # successfully import key material into a CMK, you can [reimport the
    # same key material][1] into that CMK, but you cannot import different
    # key material.
    #
    # You cannot perform this operation on an asymmetric CMK or on any CMK
    # in a different AWS account. For more information about creating CMKs
    # with no key material and then importing key material, see [Importing
    # Key Material][2] in the *AWS Key Management Service Developer Guide*.
    #
    # Before using this operation, call GetParametersForImport. Its response
    # includes a public key and an import token. Use the public key to
    # encrypt the key material. Then, submit the import token from the same
    # `GetParametersForImport` response.
    #
    # When calling this operation, you must specify the following values:
    #
    # * The key ID or key ARN of a CMK with no key material. Its `Origin`
    #   must be `EXTERNAL`.
    #
    #   To create a CMK with no key material, call CreateKey and set the
    #   value of its `Origin` parameter to `EXTERNAL`. To get the `Origin`
    #   of a CMK, call DescribeKey.)
    #
    # * The encrypted key material. To get the public key to encrypt the key
    #   material, call GetParametersForImport.
    #
    # * The import token that GetParametersForImport returned. You must use
    #   a public key and token from the same `GetParametersForImport`
    #   response.
    #
    # * Whether the key material expires and if so, when. If you set an
    #   expiration date, AWS KMS deletes the key material from the CMK on
    #   the specified date, and the CMK becomes unusable. To use the CMK
    #   again, you must reimport the same key material. The only way to
    #   change an expiration date is by reimporting the same key material
    #   and specifying a new expiration date.
    #
    # When this operation is successful, the key state of the CMK changes
    # from `PendingImport` to `Enabled`, and you can use the CMK.
    #
    # If this operation fails, use the exception to help determine the
    # problem. If the error is related to the key material, the import
    # token, or wrapping key, use GetParametersForImport to get a new public
    # key and import token for the CMK and repeat the import procedure. For
    # help, see [How To Import Key Material][3] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][4] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the symmetric CMK that receives the imported key
    #   material. The CMK's `Origin` must be `EXTERNAL`. This must be the
    #   same CMK specified in the `KeyID` parameter of the corresponding
    #   GetParametersForImport request.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String, StringIO, File] :import_token
    #   The import token that you received in the response to a previous
    #   GetParametersForImport request. It must be from the same response that
    #   contained the public key that you used to encrypt the key material.
    #
    # @option params [required, String, StringIO, File] :encrypted_key_material
    #   The encrypted key material to import. The key material must be
    #   encrypted with the public wrapping key that GetParametersForImport
    #   returned, using the wrapping algorithm that you specified in the same
    #   `GetParametersForImport` request.
    #
    # @option params [Time,DateTime,Date,Integer,String] :valid_to
    #   The time at which the imported key material expires. When the key
    #   material expires, AWS KMS deletes the key material and the CMK becomes
    #   unusable. You must omit this parameter when the `ExpirationModel`
    #   parameter is set to `KEY_MATERIAL_DOES_NOT_EXPIRE`. Otherwise it is
    #   required.
    #
    # @option params [String] :expiration_model
    #   Specifies whether the key material expires. The default is
    #   `KEY_MATERIAL_EXPIRES`, in which case you must include the `ValidTo`
    #   parameter. When this parameter is set to
    #   `KEY_MATERIAL_DOES_NOT_EXPIRE`, you must omit the `ValidTo` parameter.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To import key material into a customer master key (CMK)
    #
    #   # The following example imports key material into the specified CMK.
    #
    #   resp = client.import_key_material({
    #     encrypted_key_material: "<binary data>", # The encrypted key material to import.
    #     expiration_model: "KEY_MATERIAL_DOES_NOT_EXPIRE", # A value that specifies whether the key material expires.
    #     import_token: "<binary data>", # The import token that you received in the response to a previous GetParametersForImport request.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to import the key material into. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.import_key_material({
    #     key_id: "KeyIdType", # required
    #     import_token: "data", # required
    #     encrypted_key_material: "data", # required
    #     valid_to: Time.now,
    #     expiration_model: "KEY_MATERIAL_EXPIRES", # accepts KEY_MATERIAL_EXPIRES, KEY_MATERIAL_DOES_NOT_EXPIRE
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ImportKeyMaterial AWS API Documentation
    #
    # @overload import_key_material(params = {})
    # @param [Hash] params ({})
    def import_key_material(params = {}, options = {})
      req = build_request(:import_key_material, params)
      req.send_request(options)
    end

    # Gets a list of aliases in the caller's AWS account and region. You
    # cannot list aliases in other accounts. For more information about
    # aliases, see CreateAlias.
    #
    # By default, the ListAliases command returns all aliases in the account
    # and region. To get only the aliases that point to a particular
    # customer master key (CMK), use the `KeyId` parameter.
    #
    # The `ListAliases` response can include aliases that you created and
    # associated with your customer managed CMKs, and aliases that AWS
    # created and associated with AWS managed CMKs in your account. You can
    # recognize AWS aliases because their names have the format
    # `aws/<service-name>`, such as `aws/dynamodb`.
    #
    # The response might also include aliases that have no `TargetKeyId`
    # field. These are predefined aliases that AWS has created but has not
    # yet associated with a CMK. Aliases that AWS creates in your account,
    # including predefined aliases, do not count against your [AWS KMS
    # aliases quota][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit
    #
    # @option params [String] :key_id
    #   Lists only aliases that refer to the specified CMK. The value of this
    #   parameter can be the ID or Amazon Resource Name (ARN) of a CMK in the
    #   caller's account and region. You cannot use an alias name or alias
    #   ARN in this value.
    #
    #   This parameter is optional. If you omit it, `ListAliases` returns all
    #   aliases in the account and region.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListAliasesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListAliasesResponse#aliases #aliases} => Array&lt;Types::AliasListEntry&gt;
    #   * {Types::ListAliasesResponse#next_marker #next_marker} => String
    #   * {Types::ListAliasesResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list aliases
    #
    #   # The following example lists aliases.
    #
    #   resp = client.list_aliases({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     aliases: [
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/acm", 
    #         alias_name: "alias/aws/acm", 
    #         target_key_id: "da03f6f7-d279-427a-9cae-de48d07e5b66", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/ebs", 
    #         alias_name: "alias/aws/ebs", 
    #         target_key_id: "25a217e7-7170-4b8c-8bf6-045ea5f70e5b", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/rds", 
    #         alias_name: "alias/aws/rds", 
    #         target_key_id: "7ec3104e-c3f2-4b5c-bf42-bfc4772c6685", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/redshift", 
    #         alias_name: "alias/aws/redshift", 
    #         target_key_id: "08f7a25a-69e2-4fb5-8f10-393db27326fa", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/s3", 
    #         alias_name: "alias/aws/s3", 
    #         target_key_id: "d2b0f1a3-580d-4f79-b836-bc983be8cfa5", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example1", 
    #         alias_name: "alias/example1", 
    #         target_key_id: "4da1e216-62d0-46c5-a7c0-5f3a3d2f8046", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example2", 
    #         alias_name: "alias/example2", 
    #         target_key_id: "f32fef59-2cc2-445b-8573-2d73328acbee", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example3", 
    #         alias_name: "alias/example3", 
    #         target_key_id: "1374ef38-d34e-4d5f-b2c9-4e0daee38855", 
    #       }, 
    #     ], # A list of aliases, including the key ID of the customer master key (CMK) that each alias refers to.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_aliases({
    #     key_id: "KeyIdType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.aliases #=> Array
    #   resp.aliases[0].alias_name #=> String
    #   resp.aliases[0].alias_arn #=> String
    #   resp.aliases[0].target_key_id #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListAliases AWS API Documentation
    #
    # @overload list_aliases(params = {})
    # @param [Hash] params ({})
    def list_aliases(params = {}, options = {})
      req = build_request(:list_aliases, params)
      req.send_request(options)
    end

    # Gets a list of all grants for the specified customer master key (CMK).
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    # <note markdown="1"> The `GranteePrincipal` field in the `ListGrants` response usually
    # contains the user or role designated as the grantee principal in the
    # grant. However, when the grantee principal in the grant is an AWS
    # service, the `GranteePrincipal` field contains the [service
    # principal][1], which might represent several different grantee
    # principals.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-services
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list grants for a customer master key (CMK)
    #
    #   # The following example lists grants for the specified CMK.
    #
    #   resp = client.list_grants({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose grants you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "91ad875e49b04a9d1f3bdeb84d821f9db6ea95e1098813f6d47f0c65fbe2a172", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "a5d67d3e207a8fc1f4928749ee3e52eb0440493a8b9cf05bbfad91655b056200", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "c541aaf05d90cb78846a73b346fc43e65be28b7163129488c738e0c9e0628f4f", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "dd2052c67b4c76ee45caf1dc6a1e2d24e8dc744a51b36ae2f067dc540ce0105c", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #     ], # A list of grants.
    #     truncated: true, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "Sign", "Verify", "GetPublicKey", "CreateGrant", "RetireGrant", "DescribeKey", "GenerateDataKeyPair", "GenerateDataKeyPairWithoutPlaintext"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListGrants AWS API Documentation
    #
    # @overload list_grants(params = {})
    # @param [Hash] params ({})
    def list_grants(params = {}, options = {})
      req = build_request(:list_grants, params)
      req.send_request(options)
    end

    # Gets the names of the key policies that are attached to a customer
    # master key (CMK). This operation is designed to get policy names that
    # you can use in a GetKeyPolicy operation. However, the only valid
    # policy name is `default`. You cannot perform this operation on a CMK
    # in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    #   Only one policy can be attached to a key.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeyPoliciesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeyPoliciesResponse#policy_names #policy_names} => Array&lt;String&gt;
    #   * {Types::ListKeyPoliciesResponse#next_marker #next_marker} => String
    #   * {Types::ListKeyPoliciesResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list key policies for a customer master key (CMK)
    #
    #   # The following example lists key policies for the specified CMK.
    #
    #   resp = client.list_key_policies({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key policies you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy_names: [
    #       "default", 
    #     ], # A list of key policy names.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_key_policies({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy_names #=> Array
    #   resp.policy_names[0] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyPolicies AWS API Documentation
    #
    # @overload list_key_policies(params = {})
    # @param [Hash] params ({})
    def list_key_policies(params = {}, options = {})
      req = build_request(:list_key_policies, params)
      req.send_request(options)
    end

    # Gets a list of all customer master keys (CMKs) in the caller's AWS
    # account and Region.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeysResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeysResponse#keys #keys} => Array&lt;Types::KeyListEntry&gt;
    #   * {Types::ListKeysResponse#next_marker #next_marker} => String
    #   * {Types::ListKeysResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list customer master keys (CMKs)
    #
    #   # The following example lists CMKs.
    #
    #   resp = client.list_keys({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     keys: [
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/0d990263-018e-4e65-a703-eff731de951e", 
    #         key_id: "0d990263-018e-4e65-a703-eff731de951e", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #         key_id: "144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/21184251-b765-428e-b852-2c7353e72571", 
    #         key_id: "21184251-b765-428e-b852-2c7353e72571", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #         key_id: "214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/339963f2-e523-49d3-af24-a0fe752aa458", 
    #         key_id: "339963f2-e523-49d3-af24-a0fe752aa458", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/b776a44b-df37-4438-9be4-a27494e4271a", 
    #         key_id: "b776a44b-df37-4438-9be4-a27494e4271a", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #         key_id: "deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #       }, 
    #     ], # A list of CMKs, including the key ID and Amazon Resource Name (ARN) of each one.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_keys({
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.keys #=> Array
    #   resp.keys[0].key_id #=> String
    #   resp.keys[0].key_arn #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeys AWS API Documentation
    #
    # @overload list_keys(params = {})
    # @param [Hash] params ({})
    def list_keys(params = {}, options = {})
      req = build_request(:list_keys, params)
      req.send_request(options)
    end

    # Returns a list of all tags for the specified customer master key
    # (CMK).
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 50, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    #   Do not attempt to construct this value. Use only the value of
    #   `NextMarker` from the truncated response you just received.
    #
    # @return [Types::ListResourceTagsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListResourceTagsResponse#tags #tags} => Array&lt;Types::Tag&gt;
    #   * {Types::ListResourceTagsResponse#next_marker #next_marker} => String
    #   * {Types::ListResourceTagsResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list tags for a customer master key (CMK)
    #
    #   # The following example lists tags for a CMK.
    #
    #   resp = client.list_resource_tags({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose tags you are listing. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tags: [
    #       {
    #         tag_key: "CostCenter", 
    #         tag_value: "87654", 
    #       }, 
    #       {
    #         tag_key: "CreatedBy", 
    #         tag_value: "ExampleUser", 
    #       }, 
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_resource_tags({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.tags #=> Array
    #   resp.tags[0].tag_key #=> String
    #   resp.tags[0].tag_value #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListResourceTags AWS API Documentation
    #
    # @overload list_resource_tags(params = {})
    # @param [Hash] params ({})
    def list_resource_tags(params = {}, options = {})
      req = build_request(:list_resource_tags, params)
      req.send_request(options)
    end

    # Returns a list of all grants for which the grant's
    # `RetiringPrincipal` matches the one specified.
    #
    # A typical use is to list all grants that you are able to retire. To
    # retire a grant, use RetireGrant.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :retiring_principal
    #   The retiring principal for which to list grants.
    #
    #   To specify the retiring principal, use the [Amazon Resource Name
    #   (ARN)][1] of an AWS principal. Valid AWS principals include AWS
    #   accounts (root), IAM users, federated users, and assumed role users.
    #   For examples of the ARN syntax for specifying a principal, see [AWS
    #   Identity and Access Management (IAM)][2] in the Example ARNs section
    #   of the *Amazon Web Services General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list grants that the specified principal can retire
    #
    #   # The following example lists the grants that the specified principal (identity) can retire.
    #
    #   resp = client.list_retirable_grants({
    #     retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The retiring principal whose grants you want to list. Use the Amazon Resource Name (ARN) of an AWS principal such as an AWS account (root), IAM user, federated user, or assumed role user.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-12-07T11:09:35-08:00"), 
    #         grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", 
    #         grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #         issuing_account: "arn:aws:iam::444455556666:root", 
    #         key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Decrypt", 
    #           "Encrypt", 
    #         ], 
    #         retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #       }, 
    #     ], # A list of grants that the specified principal can retire.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_retirable_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     retiring_principal: "PrincipalIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "Sign", "Verify", "GetPublicKey", "CreateGrant", "RetireGrant", "DescribeKey", "GenerateDataKeyPair", "GenerateDataKeyPairWithoutPlaintext"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListRetirableGrants AWS API Documentation
    #
    # @overload list_retirable_grants(params = {})
    # @param [Hash] params ({})
    def list_retirable_grants(params = {}, options = {})
      req = build_request(:list_retirable_grants, params)
      req.send_request(options)
    end

    # Attaches a key policy to the specified customer master key (CMK). You
    # cannot perform this operation on a CMK in a different AWS account.
    #
    # For more information about key policies, see [Key Policies][1] in the
    # *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :policy_name
    #   The name of the key policy. The only valid value is `default`.
    #
    # @option params [required, String] :policy
    #   The key policy to attach to the CMK.
    #
    #   The key policy must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the key
    #     policy must allow the principal that is making the `PutKeyPolicy`
    #     request to make a subsequent `PutKeyPolicy` request on the CMK. This
    #     reduces the risk that the CMK becomes unmanageable. For more
    #     information, refer to the scenario in the [Default Key Policy][1]
    #     section of the *AWS Key Management Service Developer Guide*.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User Guide*.
    #
    #   The key policy cannot exceed 32 kilobytes (32768 bytes). For more
    #   information, see [Resource Quotas][3] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/resource-limits.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the *AWS Key Management Service Developer
    #   Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal that
    #   is making the request from making a subsequent `PutKeyPolicy` request
    #   on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To attach a key policy to a customer master key (CMK)
    #
    #   # The following example attaches a key policy to the specified CMK.
    #
    #   resp = client.put_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to attach the key policy to. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     policy: "{\"Version\":\"2012-10-17\",\"Id\":\"custom-policy-2016-12-07\",\"Statement\":[{\"Sid\":\"EnableIAMUserPermissions\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:root\"},\"Action\":\"kms:*\",\"Resource\":\"*\"},{\"Sid\":\"AllowaccessforKeyAdministrators\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"arn:aws:iam::111122223333:user/ExampleAdminUser\",\"arn:aws:iam::111122223333:role/ExampleAdminRole\"]},\"Action\":[\"kms:Create*\",\"kms:Describe*\",\"kms:Enable*\",\"kms:List*\",\"kms:Put*\",\"kms:Update*\",\"kms:Revoke*\",\"kms:Disable*\",\"kms:Get*\",\"kms:Delete*\",\"kms:ScheduleKeyDeletion\",\"kms:CancelKeyDeletion\"],\"Resource\":\"*\"},{\"Sid\":\"Allowuseofthekey\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:Encrypt\",\"kms:Decrypt\",\"kms:ReEncrypt*\",\"kms:GenerateDataKey*\",\"kms:DescribeKey\"],\"Resource\":\"*\"},{\"Sid\":\"Allowattachmentofpersistentresources\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:CreateGrant\",\"kms:ListGrants\",\"kms:RevokeGrant\"],\"Resource\":\"*\",\"Condition\":{\"Bool\":{\"kms:GrantIsForAWSResource\":\"true\"}}}]}", # The key policy document.
    #     policy_name: "default", # The name of the key policy.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType", # required
    #     policy: "PolicyType", # required
    #     bypass_policy_lockout_safety_check: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/PutKeyPolicy AWS API Documentation
    #
    # @overload put_key_policy(params = {})
    # @param [Hash] params ({})
    def put_key_policy(params = {}, options = {})
      req = build_request(:put_key_policy, params)
      req.send_request(options)
    end

    # Decrypts ciphertext and then reencrypts it entirely within AWS KMS.
    # You can use this operation to change the customer master key (CMK)
    # under which data is encrypted, such as when you [manually rotate][1] a
    # CMK or change the CMK that protects a ciphertext. You can also use it
    # to reencrypt ciphertext under the same CMK, such as to change the
    # [encryption context][2] of a ciphertext.
    #
    # The `ReEncrypt` operation can decrypt ciphertext that was encrypted by
    # using an AWS KMS CMK in an AWS KMS operation, such as Encrypt or
    # GenerateDataKey. It can also decrypt ciphertext that was encrypted by
    # using the public key of an [asymmetric CMK][3] outside of AWS KMS.
    # However, it cannot decrypt ciphertext produced by other libraries,
    # such as the [AWS Encryption SDK][4] or [Amazon S3 client-side
    # encryption][5]. These libraries return a ciphertext format that is
    # incompatible with AWS KMS.
    #
    # When you use the `ReEncrypt` operation, you need to provide
    # information for the decrypt operation and the subsequent encrypt
    # operation.
    #
    # * If your ciphertext was encrypted under an asymmetric CMK, you must
    #   identify the *source CMK*, that is, the CMK that encrypted the
    #   ciphertext. You must also supply the encryption algorithm that was
    #   used. This information is required to decrypt the data.
    #
    # * It is optional, but you can specify a source CMK even when the
    #   ciphertext was encrypted under a symmetric CMK. This ensures that
    #   the ciphertext is decrypted only by using a particular CMK. If the
    #   CMK that you specify cannot decrypt the ciphertext, the `ReEncrypt`
    #   operation fails.
    #
    # * To reencrypt the data, you must specify the *destination CMK*, that
    #   is, the CMK that re-encrypts the data after it is decrypted. You can
    #   select a symmetric or asymmetric CMK. If the destination CMK is an
    #   asymmetric CMK, you must also provide the encryption algorithm. The
    #   algorithm that you choose must be compatible with the CMK.
    #
    #   When you use an asymmetric CMK to encrypt or reencrypt data, be sure
    #   to record the CMK and encryption algorithm that you choose. You will
    #   be required to provide the same CMK and encryption algorithm when
    #   you decrypt the data. If the CMK and algorithm do not match the
    #   values used to encrypt the data, the decrypt operation fails.
    #
    #    You are not required to supply the CMK ID and encryption algorithm
    #   when you decrypt with symmetric CMKs because AWS KMS stores this
    #   information in the ciphertext blob. AWS KMS cannot store metadata in
    #   ciphertext generated with asymmetric keys. The standard format for
    #   asymmetric key ciphertext does not include configurable fields.
    #
    # Unlike other AWS KMS API operations, `ReEncrypt` callers must have two
    # permissions:
    #
    # * `kms:ReEncryptFrom` permission on the source CMK
    #
    # * `kms:ReEncryptTo` permission on the destination CMK
    #
    # To permit reencryption from or to a CMK, include the
    # `"kms:ReEncrypt*"` permission in your [key policy][6]. This permission
    # is automatically included in the key policy when you use the console
    # to create a CMK. But you must include it manually when you create a
    # CMK programmatically or when you use the PutKeyPolicy operation to set
    # a key policy.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][7] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symm-asymm-concepts.html#asymmetric-cmks
    # [4]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String, StringIO, File] :ciphertext_blob
    #   Ciphertext of the data to reencrypt.
    #
    # @option params [Hash<String,String>] :source_encryption_context
    #   Specifies the encryption context to use to decrypt the ciphertext.
    #   Enter the same encryption context that was used to encrypt the
    #   ciphertext.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [String] :source_key_id
    #   A unique identifier for the CMK that is used to decrypt the ciphertext
    #   before it reencrypts it using the destination CMK.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric CMK. Otherwise, AWS KMS uses the metadata that it
    #   adds to the ciphertext blob to determine which CMK was used to encrypt
    #   the ciphertext. However, you can use this parameter to ensure that a
    #   particular CMK (of any kind) is used to decrypt the ciphertext before
    #   it is reencrypted.
    #
    #   If you specify a `KeyId` value, the decrypt part of the `ReEncrypt`
    #   operation succeeds only if the specified CMK was used to encrypt the
    #   ciphertext.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :destination_key_id
    #   A unique identifier for the CMK that is used to reencrypt the data.
    #   Specify a symmetric or asymmetric CMK with a `KeyUsage` value of
    #   `ENCRYPT_DECRYPT`. To find the `KeyUsage` value of a CMK, use the
    #   DescribeKey operation.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :destination_encryption_context
    #   Specifies that encryption context to use when the reencrypting the
    #   data.
    #
    #   A destination encryption context is valid only when the destination
    #   CMK is a symmetric CMK. The standard ciphertext format for asymmetric
    #   CMKs does not include fields for metadata.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represents additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is optional when encrypting with a symmetric CMK,
    #   but it is highly recommended.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [String] :source_encryption_algorithm
    #   Specifies the encryption algorithm that AWS KMS will use to decrypt
    #   the ciphertext before it is reencrypted. The default value,
    #   `SYMMETRIC_DEFAULT`, represents the algorithm used for symmetric CMKs.
    #
    #   Specify the same algorithm that was used to encrypt the ciphertext. If
    #   you specify a different algorithm, the decrypt attempt fails.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric CMK.
    #
    # @option params [String] :destination_encryption_algorithm
    #   Specifies the encryption algorithm that AWS KMS will use to reecrypt
    #   the data after it has decrypted it. The default value,
    #   `SYMMETRIC_DEFAULT`, represents the encryption algorithm used for
    #   symmetric CMKs.
    #
    #   This parameter is required only when the destination CMK is an
    #   asymmetric CMK.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::ReEncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ReEncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::ReEncryptResponse#source_key_id #source_key_id} => String
    #   * {Types::ReEncryptResponse#key_id #key_id} => String
    #   * {Types::ReEncryptResponse#source_encryption_algorithm #source_encryption_algorithm} => String
    #   * {Types::ReEncryptResponse#destination_encryption_algorithm #destination_encryption_algorithm} => String
    #
    #
    # @example Example: To reencrypt data
    #
    #   # The following example reencrypts data with the specified CMK.
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "<binary data>", # The data to reencrypt.
    #     destination_key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", # The identifier of the CMK to use to reencrypt the data. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The reencrypted data.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The ARN of the CMK that was used to reencrypt the data.
    #     source_key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to originally encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "data", # required
    #     source_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     source_key_id: "KeyIdType",
    #     destination_key_id: "KeyIdType", # required
    #     destination_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     source_encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #     destination_encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.source_key_id #=> String
    #   resp.key_id #=> String
    #   resp.source_encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #   resp.destination_encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReEncrypt AWS API Documentation
    #
    # @overload re_encrypt(params = {})
    # @param [Hash] params ({})
    def re_encrypt(params = {}, options = {})
      req = build_request(:re_encrypt, params)
      req.send_request(options)
    end

    # Retires a grant. To clean up, you can retire a grant when you're done
    # using it. You should revoke a grant when you intend to actively deny
    # operations that depend on it. The following are permitted to call this
    # API:
    #
    # * The AWS account (root user) under which the grant was created
    #
    # * The `RetiringPrincipal`, if present in the grant
    #
    # * The `GranteePrincipal`, if `RetireGrant` is an operation specified
    #   in the grant
    #
    # You must identify the grant to retire by its grant token or by a
    # combination of the grant ID and the Amazon Resource Name (ARN) of the
    # customer master key (CMK). A grant token is a unique variable-length
    # base64-encoded string. A grant ID is a 64 character unique identifier
    # of a grant. The CreateGrant operation returns both.
    #
    # @option params [String] :grant_token
    #   Token that identifies the grant to be retired.
    #
    # @option params [String] :key_id
    #   The Amazon Resource Name (ARN) of the CMK associated with the grant.
    #
    #   For example:
    #   `arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    # @option params [String] :grant_id
    #   Unique identifier of the grant to retire. The grant ID is returned in
    #   the response to a `CreateGrant` operation.
    #
    #   * Grant ID Example -
    #     0123456789012345678901234567890123456789012345678901234567890123
    #
    #   ^
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To retire a grant
    #
    #   # The following example retires a grant.
    #
    #   resp = client.retire_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to retire.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the customer master key (CMK) associated with the grant.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.retire_grant({
    #     grant_token: "GrantTokenType",
    #     key_id: "KeyIdType",
    #     grant_id: "GrantIdType",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RetireGrant AWS API Documentation
    #
    # @overload retire_grant(params = {})
    # @param [Hash] params ({})
    def retire_grant(params = {}, options = {})
      req = build_request(:retire_grant, params)
      req.send_request(options)
    end

    # Revokes the specified grant for the specified customer master key
    # (CMK). You can revoke a grant to actively deny operations that depend
    # on it.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key associated with the
    #   grant.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :grant_id
    #   Identifier of the grant to be revoked.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To revoke a grant
    #
    #   # The following example revokes a grant.
    #
    #   resp = client.revoke_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to revoke.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the customer master key (CMK) associated with the grant. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.revoke_grant({
    #     key_id: "KeyIdType", # required
    #     grant_id: "GrantIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RevokeGrant AWS API Documentation
    #
    # @overload revoke_grant(params = {})
    # @param [Hash] params ({})
    def revoke_grant(params = {}, options = {})
      req = build_request(:revoke_grant, params)
      req.send_request(options)
    end

    # Schedules the deletion of a customer master key (CMK). You may provide
    # a waiting period, specified in days, before deletion occurs. If you do
    # not provide a waiting period, the default period of 30 days is used.
    # When this operation is successful, the key state of the CMK changes to
    # `PendingDeletion`. Before the waiting period ends, you can use
    # CancelKeyDeletion to cancel the deletion of the CMK. After the waiting
    # period ends, AWS KMS deletes the CMK and all AWS KMS data associated
    # with it, including all aliases that refer to it.
    #
    # Deleting a CMK is a destructive and potentially dangerous operation.
    # When a CMK is deleted, all data that was encrypted under the CMK is
    # unrecoverable. To prevent the use of a CMK without deleting it, use
    # DisableKey.
    #
    # If you schedule deletion of a CMK from a [custom key store][1], when
    # the waiting period expires, `ScheduleKeyDeletion` deletes the CMK from
    # AWS KMS. Then AWS KMS makes a best effort to delete the key material
    # from the associated AWS CloudHSM cluster. However, you might need to
    # manually [delete the orphaned key material][2] from the cluster and
    # its backups.
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # For more information about scheduling a CMK for deletion, see
    # [Deleting Customer Master Keys][3] in the *AWS Key Management Service
    # Developer Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][4] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier of the customer master key (CMK) to delete.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :pending_window_in_days
    #   The waiting period, specified in number of days. After the waiting
    #   period ends, AWS KMS deletes the customer master key (CMK).
    #
    #   This value is optional. If you include a value, it must be between 7
    #   and 30, inclusive. If you do not include a value, it defaults to 30.
    #
    # @return [Types::ScheduleKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ScheduleKeyDeletionResponse#key_id #key_id} => String
    #   * {Types::ScheduleKeyDeletionResponse#deletion_date #deletion_date} => Time
    #
    #
    # @example Example: To schedule a customer master key (CMK) for deletion
    #
    #   # The following example schedules the specified CMK for deletion.
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to schedule for deletion. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     pending_window_in_days: 7, # The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     deletion_date: Time.parse("2016-12-17T16:00:00-08:00"), # The date and time after which AWS KMS deletes the CMK.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that is scheduled for deletion.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "KeyIdType", # required
    #     pending_window_in_days: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.deletion_date #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ScheduleKeyDeletion AWS API Documentation
    #
    # @overload schedule_key_deletion(params = {})
    # @param [Hash] params ({})
    def schedule_key_deletion(params = {}, options = {})
      req = build_request(:schedule_key_deletion, params)
      req.send_request(options)
    end

    # Creates a [digital signature][1] for a message or message digest by
    # using the private key in an asymmetric CMK. To verify the signature,
    # use the Verify operation, or use the public key in the same asymmetric
    # CMK outside of AWS KMS. For information about symmetric and asymmetric
    # CMKs, see [Using Symmetric and Asymmetric CMKs][2] in the *AWS Key
    # Management Service Developer Guide*.
    #
    # Digital signatures are generated and verified by using asymmetric key
    # pair, such as an RSA or ECC pair that is represented by an asymmetric
    # customer master key (CMK). The key owner (or an authorized user) uses
    # their private key to sign a message. Anyone with the public key can
    # verify that the message was signed with that particular private key
    # and that the message hasn't changed since it was signed.
    #
    # To use the `Sign` operation, provide the following information:
    #
    # * Use the `KeyId` parameter to identify an asymmetric CMK with a
    #   `KeyUsage` value of `SIGN_VERIFY`. To get the `KeyUsage` value of a
    #   CMK, use the DescribeKey operation. The caller must have `kms:Sign`
    #   permission on the CMK.
    #
    # * Use the `Message` parameter to specify the message or message digest
    #   to sign. You can submit messages of up to 4096 bytes. To sign a
    #   larger message, generate a hash digest of the message, and then
    #   provide the hash digest in the `Message` parameter. To indicate
    #   whether the message is a full message or a digest, use the
    #   `MessageType` parameter.
    #
    # * Choose a signing algorithm that is compatible with the CMK.
    #
    # When signing a message, be sure to record the CMK and the signing
    # algorithm. This information is required to verify the signature.
    #
    # To verify the signature that this operation generates, use the Verify
    # operation. Or use the GetPublicKey operation to download the public
    # key and then use the public key to verify the signature outside of AWS
    # KMS.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][3] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://en.wikipedia.org/wiki/Digital_signature
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies an asymmetric CMK. AWS KMS uses the private key in the
    #   asymmetric CMK to sign the message. The `KeyUsage` type of the CMK
    #   must be `SIGN_VERIFY`. To find the `KeyUsage` of a CMK, use the
    #   DescribeKey operation.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :message
    #   Specifies the message or message digest to sign. Messages can be
    #   0-4096 bytes. To sign a larger message, provide the message digest.
    #
    #   If you provide a message, AWS KMS generates a hash digest of the
    #   message and then signs it.
    #
    # @option params [String] :message_type
    #   Tells AWS KMS whether the value of the `Message` parameter is a
    #   message or message digest. The default value, RAW, indicates a
    #   message. To indicate a message digest, enter `DIGEST`.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @option params [required, String] :signing_algorithm
    #   Specifies the signing algorithm to use when signing the message.
    #
    #   Choose an algorithm that is compatible with the type and size of the
    #   specified asymmetric CMK.
    #
    # @return [Types::SignResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::SignResponse#key_id #key_id} => String
    #   * {Types::SignResponse#signature #signature} => String
    #   * {Types::SignResponse#signing_algorithm #signing_algorithm} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.sign({
    #     key_id: "KeyIdType", # required
    #     message: "data", # required
    #     message_type: "RAW", # accepts RAW, DIGEST
    #     grant_tokens: ["GrantTokenType"],
    #     signing_algorithm: "RSASSA_PSS_SHA_256", # required, accepts RSASSA_PSS_SHA_256, RSASSA_PSS_SHA_384, RSASSA_PSS_SHA_512, RSASSA_PKCS1_V1_5_SHA_256, RSASSA_PKCS1_V1_5_SHA_384, RSASSA_PKCS1_V1_5_SHA_512, ECDSA_SHA_256, ECDSA_SHA_384, ECDSA_SHA_512
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.signature #=> String
    #   resp.signing_algorithm #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Sign AWS API Documentation
    #
    # @overload sign(params = {})
    # @param [Hash] params ({})
    def sign(params = {}, options = {})
      req = build_request(:sign, params)
      req.send_request(options)
    end

    # Adds or edits tags for a customer master key (CMK). You cannot perform
    # this operation on a CMK in a different AWS account.
    #
    # Each tag consists of a tag key and a tag value. Tag keys and tag
    # values are both required, but tag values can be empty (null) strings.
    #
    # You can only use a tag key once for each CMK. If you use the tag key
    # again, AWS KMS replaces the current tag value with the specified
    # value.
    #
    # For information about the rules that apply to tag keys and tag values,
    # see [User-Defined Tag Restrictions][1] in the *AWS Billing and Cost
    # Management User Guide*.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the CMK you are tagging.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, Array<Types::Tag>] :tags
    #   One or more tags. Each tag consists of a tag key and a tag value.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To tag a customer master key (CMK)
    #
    #   # The following example tags a CMK.
    #
    #   resp = client.tag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK you are tagging. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     tags: [
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.tag_resource({
    #     key_id: "KeyIdType", # required
    #     tags: [ # required
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/TagResource AWS API Documentation
    #
    # @overload tag_resource(params = {})
    # @param [Hash] params ({})
    def tag_resource(params = {}, options = {})
      req = build_request(:tag_resource, params)
      req.send_request(options)
    end

    # Removes the specified tags from the specified customer master key
    # (CMK). You cannot perform this operation on a CMK in a different AWS
    # account.
    #
    # To remove a tag, specify the tag key. To change the tag value of an
    # existing tag key, use TagResource.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the CMK from which you are removing tags.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, Array<String>] :tag_keys
    #   One or more tag keys. Specify only the tag keys, not the tag values.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To remove tags from a customer master key (CMK)
    #
    #   # The following example removes tags from a CMK.
    #
    #   resp = client.untag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose tags you are removing.
    #     tag_keys: [
    #       "Purpose", 
    #       "CostCenter", 
    #     ], # A list of tag keys. Provide only the tag keys, not the tag values.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.untag_resource({
    #     key_id: "KeyIdType", # required
    #     tag_keys: ["TagKeyType"], # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UntagResource AWS API Documentation
    #
    # @overload untag_resource(params = {})
    # @param [Hash] params ({})
    def untag_resource(params = {}, options = {})
      req = build_request(:untag_resource, params)
      req.send_request(options)
    end

    # Associates an existing AWS KMS alias with a different customer master
    # key (CMK). Each alias is associated with only one CMK at a time,
    # although a CMK can have multiple aliases. The alias and the CMK must
    # be in the same AWS account and region. You cannot perform this
    # operation on an alias in a different AWS account.
    #
    # The current and new CMK must be the same type (both symmetric or both
    # asymmetric), and they must have the same key usage (`ENCRYPT_DECRYPT`
    # or `SIGN_VERIFY`). This restriction prevents errors in code that uses
    # aliases. If you must assign an alias to a different type of CMK, use
    # DeleteAlias to delete the old alias and CreateAlias to create a new
    # alias.
    #
    # You cannot use `UpdateAlias` to change an alias name. To change an
    # alias name, use DeleteAlias to delete the old alias and CreateAlias to
    # create a new alias.
    #
    # Because an alias is not a property of a CMK, you can create, update,
    # and delete the aliases of a CMK without affecting the CMK. Also,
    # aliases do not appear in the response from the DescribeKey operation.
    # To get the aliases of all CMKs in the account, use the ListAliases
    # operation.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :alias_name
    #   Identifies the alias that is changing its CMK. This value must begin
    #   with `alias/` followed by the alias name, such as
    #   `alias/ExampleAlias`. You cannot use UpdateAlias to change the alias
    #   name.
    #
    # @option params [required, String] :target_key_id
    #   Identifies the CMK to associate with the alias. When the update
    #   operation completes, the alias will point to this CMK.
    #
    #   The CMK must be in the same AWS account and Region as the alias. Also,
    #   the new target CMK must be the same type as the current target CMK
    #   (both symmetric or both asymmetric) and they must have the same key
    #   usage.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    #   To verify that the alias is mapped to the correct CMK, use
    #   ListAliases.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update an alias
    #
    #   # The following example updates the specified alias to refer to the specified customer master key (CMK).
    #
    #   resp = client.update_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to update.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK that the alias will refer to after this operation succeeds. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateAlias AWS API Documentation
    #
    # @overload update_alias(params = {})
    # @param [Hash] params ({})
    def update_alias(params = {}, options = {})
      req = build_request(:update_alias, params)
      req.send_request(options)
    end

    # Changes the properties of a custom key store. Use the
    # `CustomKeyStoreId` parameter to identify the custom key store you want
    # to edit. Use the remaining parameters to change the properties of the
    # custom key store.
    #
    # You can only update a custom key store that is disconnected. To
    # disconnect the custom key store, use DisconnectCustomKeyStore. To
    # reconnect the custom key store after the update completes, use
    # ConnectCustomKeyStore. To find the connection state of a custom key
    # store, use the DescribeCustomKeyStores operation.
    #
    # Use the parameters of `UpdateCustomKeyStore` to edit your keystore
    # settings.
    #
    # * Use the **NewCustomKeyStoreName** parameter to change the friendly
    #   name of the custom key store to the value that you specify.
    #
    #
    #
    # * Use the **KeyStorePassword** parameter tell AWS KMS the current
    #   password of the [ `kmsuser` crypto user (CU)][1] in the associated
    #   AWS CloudHSM cluster. You can use this parameter to [fix connection
    #   failures][2] that occur when AWS KMS cannot log into the associated
    #   cluster because the `kmsuser` password has changed. This value does
    #   not change the password in the AWS CloudHSM cluster.
    #
    #
    #
    # * Use the **CloudHsmClusterId** parameter to associate the custom key
    #   store with a different, but related, AWS CloudHSM cluster. You can
    #   use this parameter to repair a custom key store if its AWS CloudHSM
    #   cluster becomes corrupted or is deleted, or when you need to create
    #   or restore a cluster from a backup.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][3] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [required, String] :custom_key_store_id
    #   Identifies the custom key store that you want to update. Enter the ID
    #   of the custom key store. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @option params [String] :new_custom_key_store_name
    #   Changes the friendly name of the custom key store to the value that
    #   you specify. The custom key store name must be unique in the AWS
    #   account.
    #
    # @option params [String] :key_store_password
    #   Enter the current password of the `kmsuser` crypto user (CU) in the
    #   AWS CloudHSM cluster that is associated with the custom key store.
    #
    #   This parameter tells AWS KMS the current password of the `kmsuser`
    #   crypto user (CU). It does not set or change the password of any users
    #   in the AWS CloudHSM cluster.
    #
    # @option params [String] :cloud_hsm_cluster_id
    #   Associates the custom key store with a related AWS CloudHSM cluster.
    #
    #   Enter the cluster ID of the cluster that you used to create the custom
    #   key store or a cluster that shares a backup history and has the same
    #   cluster certificate as the original cluster. You cannot use this
    #   parameter to associate a custom key store with an unrelated cluster.
    #   In addition, the replacement cluster must [fulfill the
    #   requirements][1] for a cluster associated with a custom key store. To
    #   view the cluster certificate of a cluster, use the
    #   [DescribeClusters][2] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    #   [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #     new_custom_key_store_name: "CustomKeyStoreNameType",
    #     key_store_password: "KeyStorePasswordType",
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateCustomKeyStore AWS API Documentation
    #
    # @overload update_custom_key_store(params = {})
    # @param [Hash] params ({})
    def update_custom_key_store(params = {}, options = {})
      req = build_request(:update_custom_key_store, params)
      req.send_request(options)
    end

    # Updates the description of a customer master key (CMK). To see the
    # description of a CMK, use DescribeKey.
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :description
    #   New description for the CMK.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update the description of a customer master key (CMK)
    #
    #   # The following example updates the description of the specified CMK.
    #
    #   resp = client.update_key_description({
    #     description: "Example description that indicates the intended use of this CMK.", # The updated description.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose description you are updating. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_key_description({
    #     key_id: "KeyIdType", # required
    #     description: "DescriptionType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateKeyDescription AWS API Documentation
    #
    # @overload update_key_description(params = {})
    # @param [Hash] params ({})
    def update_key_description(params = {}, options = {})
      req = build_request(:update_key_description, params)
      req.send_request(options)
    end

    # Verifies a digital signature that was generated by the Sign operation.
    #
    #
    #
    # Verification confirms that an authorized user signed the message with
    # the specified CMK and signing algorithm, and the message hasn't
    # changed since it was signed. If the signature is verified, the value
    # of the `SignatureValid` field in the response is `True`. If the
    # signature verification fails, the `Verify` operation fails with an
    # `KMSInvalidSignatureException` exception.
    #
    # A digital signature is generated by using the private key in an
    # asymmetric CMK. The signature is verified by using the public key in
    # the same asymmetric CMK. For information about symmetric and
    # asymmetric CMKs, see [Using Symmetric and Asymmetric CMKs][1] in the
    # *AWS Key Management Service Developer Guide*.
    #
    # To verify a digital signature, you can use the `Verify` operation.
    # Specify the same asymmetric CMK, message, and signing algorithm that
    # were used to produce the signature.
    #
    # You can also verify the digital signature by using the public key of
    # the CMK outside of AWS KMS. Use the GetPublicKey operation to download
    # the public key in the asymmetric CMK and then use the public key to
    # verify the signature outside of AWS KMS. The advantage of using the
    # `Verify` operation is that it is performed within AWS KMS. As a
    # result, it's easy to call, the operation is performed within the FIPS
    # boundary, it is logged in AWS CloudTrail, and you can use key policy
    # and IAM policy to determine who is authorized to use the CMK to verify
    # signatures.
    #
    # The CMK that you use for this operation must be in a compatible key
    # state. For details, see [How Key State Affects Use of a Customer
    # Master Key][2] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies the asymmetric CMK that will be used to verify the
    #   signature. This must be the same CMK that was used to generate the
    #   signature. If you specify a different CMK, the signature verification
    #   fails.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :message
    #   Specifies the message that was signed. You can submit a raw message of
    #   up to 4096 bytes, or a hash digest of the message. If you submit a
    #   digest, use the `MessageType` parameter with a value of `DIGEST`.
    #
    #   If the message specified here is different from the message that was
    #   signed, the signature verification fails. A message and its hash
    #   digest are considered to be the same message.
    #
    # @option params [String] :message_type
    #   Tells AWS KMS whether the value of the `Message` parameter is a
    #   message or message digest. The default value, RAW, indicates a
    #   message. To indicate a message digest, enter `DIGEST`.
    #
    #   Use the `DIGEST` value only when the value of the `Message` parameter
    #   is a message digest. If you use the `DIGEST` value with a raw message,
    #   the security of the verification operation can be compromised.
    #
    # @option params [required, String, StringIO, File] :signature
    #   The signature that the `Sign` operation generated.
    #
    # @option params [required, String] :signing_algorithm
    #   The signing algorithm that was used to sign the message. If you submit
    #   a different algorithm, the signature verification fails.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::VerifyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::VerifyResponse#key_id #key_id} => String
    #   * {Types::VerifyResponse#signature_valid #signature_valid} => Boolean
    #   * {Types::VerifyResponse#signing_algorithm #signing_algorithm} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.verify({
    #     key_id: "KeyIdType", # required
    #     message: "data", # required
    #     message_type: "RAW", # accepts RAW, DIGEST
    #     signature: "data", # required
    #     signing_algorithm: "RSASSA_PSS_SHA_256", # required, accepts RSASSA_PSS_SHA_256, RSASSA_PSS_SHA_384, RSASSA_PSS_SHA_512, RSASSA_PKCS1_V1_5_SHA_256, RSASSA_PKCS1_V1_5_SHA_384, RSASSA_PKCS1_V1_5_SHA_512, ECDSA_SHA_256, ECDSA_SHA_384, ECDSA_SHA_512
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.signature_valid #=> Boolean
    #   resp.signing_algorithm #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Verify AWS API Documentation
    #
    # @overload verify(params = {})
    # @param [Hash] params ({})
    def verify(params = {}, options = {})
      req = build_request(:verify, params)
      req.send_request(options)
    end

    # @!endgroup

    # @param params ({})
    # @api private
    def build_request(operation_name, params = {})
      handlers = @handlers.for(operation_name)
      context = Seahorse::Client::RequestContext.new(
        operation_name: operation_name,
        operation: config.api.operation(operation_name),
        client: self,
        params: params,
        config: config)
      context[:gem_name] = 'aws-sdk-kms'
      context[:gem_version] = '1.37.0'
      Seahorse::Client::Request.new(handlers, context)
    end

    # @api private
    # @deprecated
    def waiter_names
      []
    end

    class << self

      # @api private
      attr_reader :identifier

      # @api private
      def errors_module
        Errors
      end

    end
  end
end
