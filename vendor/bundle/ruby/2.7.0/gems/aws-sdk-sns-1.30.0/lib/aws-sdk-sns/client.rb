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
require 'aws-sdk-core/plugins/protocols/query.rb'

Aws::Plugins::GlobalConfiguration.add_identifier(:sns)

module Aws::SNS
  # An API client for SNS.  To construct a client, you need to configure a `:region` and `:credentials`.
  #
  #     client = Aws::SNS::Client.new(
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

    @identifier = :sns

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
    add_plugin(Aws::Plugins::Protocols::Query)

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

    # Adds a statement to a topic's access control policy, granting access
    # for the specified AWS accounts to the specified actions.
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic whose access control policy you wish to modify.
    #
    # @option params [required, String] :label
    #   A unique identifier for the new policy statement.
    #
    # @option params [required, Array<String>] :aws_account_id
    #   The AWS account IDs of the users (principals) who will be given access
    #   to the specified actions. The users must have AWS accounts, but do not
    #   need to be signed up for this service.
    #
    # @option params [required, Array<String>] :action_name
    #   The action you want to allow for the specified principal(s).
    #
    #   Valid values: Any Amazon SNS action name, for example `Publish`.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.add_permission({
    #     topic_arn: "topicARN", # required
    #     label: "label", # required
    #     aws_account_id: ["delegate"], # required
    #     action_name: ["action"], # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/AddPermission AWS API Documentation
    #
    # @overload add_permission(params = {})
    # @param [Hash] params ({})
    def add_permission(params = {}, options = {})
      req = build_request(:add_permission, params)
      req.send_request(options)
    end

    # Accepts a phone number and indicates whether the phone holder has
    # opted out of receiving SMS messages from your account. You cannot send
    # SMS messages to a number that is opted out.
    #
    # To resume sending messages, you can opt in the number by using the
    # `OptInPhoneNumber` action.
    #
    # @option params [required, String] :phone_number
    #   The phone number for which you want to check the opt out status.
    #
    # @return [Types::CheckIfPhoneNumberIsOptedOutResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CheckIfPhoneNumberIsOptedOutResponse#is_opted_out #is_opted_out} => Boolean
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.check_if_phone_number_is_opted_out({
    #     phone_number: "PhoneNumber", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.is_opted_out #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CheckIfPhoneNumberIsOptedOut AWS API Documentation
    #
    # @overload check_if_phone_number_is_opted_out(params = {})
    # @param [Hash] params ({})
    def check_if_phone_number_is_opted_out(params = {}, options = {})
      req = build_request(:check_if_phone_number_is_opted_out, params)
      req.send_request(options)
    end

    # Verifies an endpoint owner's intent to receive messages by validating
    # the token sent to the endpoint by an earlier `Subscribe` action. If
    # the token is valid, the action creates a new subscription and returns
    # its Amazon Resource Name (ARN). This call requires an AWS signature
    # only when the `AuthenticateOnUnsubscribe` flag is set to "true".
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic for which you wish to confirm a subscription.
    #
    # @option params [required, String] :token
    #   Short-lived token sent to an endpoint during the `Subscribe` action.
    #
    # @option params [String] :authenticate_on_unsubscribe
    #   Disallows unauthenticated unsubscribes of the subscription. If the
    #   value of this parameter is `true` and the request has an AWS
    #   signature, then only the topic owner and the subscription owner can
    #   unsubscribe the endpoint. The unsubscribe action requires AWS
    #   authentication.
    #
    # @return [Types::ConfirmSubscriptionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ConfirmSubscriptionResponse#subscription_arn #subscription_arn} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.confirm_subscription({
    #     topic_arn: "topicARN", # required
    #     token: "token", # required
    #     authenticate_on_unsubscribe: "authenticateOnUnsubscribe",
    #   })
    #
    # @example Response structure
    #
    #   resp.subscription_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ConfirmSubscription AWS API Documentation
    #
    # @overload confirm_subscription(params = {})
    # @param [Hash] params ({})
    def confirm_subscription(params = {}, options = {})
      req = build_request(:confirm_subscription, params)
      req.send_request(options)
    end

    # Creates a platform application object for one of the supported push
    # notification services, such as APNS and GCM (Firebase Cloud
    # Messaging), to which devices and mobile apps may register. You must
    # specify `PlatformPrincipal` and `PlatformCredential` attributes when
    # using the `CreatePlatformApplication` action.
    #
    # `PlatformPrincipal` and `PlatformCredential` are received from the
    # notification service.
    #
    # * For `ADM`, `PlatformPrincipal` is `client id` and
    #   `PlatformCredential` is `client secret`.
    #
    # * For `Baidu`, `PlatformPrincipal` is `API key` and
    #   `PlatformCredential` is `secret key`.
    #
    # * For `APNS` and `APNS_SANDBOX`, `PlatformPrincipal` is `SSL
    #   certificate` and `PlatformCredential` is `private key`.
    #
    # * For `GCM` (Firebase Cloud Messaging), there is no
    #   `PlatformPrincipal` and the `PlatformCredential` is `API key`.
    #
    # * For `MPNS`, `PlatformPrincipal` is `TLS certificate` and
    #   `PlatformCredential` is `private key`.
    #
    # * For `WNS`, `PlatformPrincipal` is `Package Security Identifier` and
    #   `PlatformCredential` is `secret key`.
    #
    # You can use the returned `PlatformApplicationArn` as an attribute for
    # the `CreatePlatformEndpoint` action.
    #
    # @option params [required, String] :name
    #   Application names must be made up of only uppercase and lowercase
    #   ASCII letters, numbers, underscores, hyphens, and periods, and must be
    #   between 1 and 256 characters long.
    #
    # @option params [required, String] :platform
    #   The following platforms are supported: ADM (Amazon Device Messaging),
    #   APNS (Apple Push Notification Service), APNS\_SANDBOX, and GCM
    #   (Firebase Cloud Messaging).
    #
    # @option params [required, Hash<String,String>] :attributes
    #   For a list of attributes, see [SetPlatformApplicationAttributes][1]
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetPlatformApplicationAttributes.html
    #
    # @return [Types::CreatePlatformApplicationResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreatePlatformApplicationResponse#platform_application_arn #platform_application_arn} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_platform_application({
    #     name: "String", # required
    #     platform: "String", # required
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    #
    # @example Response structure
    #
    #   resp.platform_application_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreatePlatformApplication AWS API Documentation
    #
    # @overload create_platform_application(params = {})
    # @param [Hash] params ({})
    def create_platform_application(params = {}, options = {})
      req = build_request(:create_platform_application, params)
      req.send_request(options)
    end

    # Creates an endpoint for a device and mobile app on one of the
    # supported push notification services, such as GCM (Firebase Cloud
    # Messaging) and APNS. `CreatePlatformEndpoint` requires the
    # `PlatformApplicationArn` that is returned from
    # `CreatePlatformApplication`. You can use the returned `EndpointArn` to
    # send a message to a mobile app or by the `Subscribe` action for
    # subscription to a topic. The `CreatePlatformEndpoint` action is
    # idempotent, so if the requester already owns an endpoint with the same
    # device token and attributes, that endpoint's ARN is returned without
    # creating a new endpoint. For more information, see [Using Amazon SNS
    # Mobile Push Notifications][1].
    #
    # When using `CreatePlatformEndpoint` with Baidu, two attributes must be
    # provided: ChannelId and UserId. The token field must also contain the
    # ChannelId. For more information, see [Creating an Amazon SNS Endpoint
    # for Baidu][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html
    #
    # @option params [required, String] :platform_application_arn
    #   PlatformApplicationArn returned from CreatePlatformApplication is used
    #   to create a an endpoint.
    #
    # @option params [required, String] :token
    #   Unique identifier created by the notification service for an app on a
    #   device. The specific name for Token will vary, depending on which
    #   notification service is being used. For example, when using APNS as
    #   the notification service, you need the device token. Alternatively,
    #   when using GCM (Firebase Cloud Messaging) or ADM, the device token
    #   equivalent is called the registration ID.
    #
    # @option params [String] :custom_user_data
    #   Arbitrary user data to associate with the endpoint. Amazon SNS does
    #   not use this data. The data must be in UTF-8 format and less than 2KB.
    #
    # @option params [Hash<String,String>] :attributes
    #   For a list of attributes, see [SetEndpointAttributes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetEndpointAttributes.html
    #
    # @return [Types::CreateEndpointResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateEndpointResponse#endpoint_arn #endpoint_arn} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_platform_endpoint({
    #     platform_application_arn: "String", # required
    #     token: "String", # required
    #     custom_user_data: "String",
    #     attributes: {
    #       "String" => "String",
    #     },
    #   })
    #
    # @example Response structure
    #
    #   resp.endpoint_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreatePlatformEndpoint AWS API Documentation
    #
    # @overload create_platform_endpoint(params = {})
    # @param [Hash] params ({})
    def create_platform_endpoint(params = {}, options = {})
      req = build_request(:create_platform_endpoint, params)
      req.send_request(options)
    end

    # Creates a topic to which notifications can be published. Users can
    # create at most 100,000 topics. For more information, see
    # [https://aws.amazon.com/sns][1]. This action is idempotent, so if the
    # requester already owns a topic with the specified name, that topic's
    # ARN is returned without creating a new topic.
    #
    #
    #
    # [1]: http://aws.amazon.com/sns/
    #
    # @option params [required, String] :name
    #   The name of the topic you want to create.
    #
    #   Constraints: Topic names must be made up of only uppercase and
    #   lowercase ASCII letters, numbers, underscores, and hyphens, and must
    #   be between 1 and 256 characters long.
    #
    # @option params [Hash<String,String>] :attributes
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `CreateTopic` action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `DisplayName` – The display name to use for a topic with SMS
    #     subscriptions.
    #
    #   * `Policy` – The policy that defines who can access your topic. By
    #     default, only the topic owner can publish or subscribe to the topic.
    #
    #   The following attribute applies only to [server-side-encryption][1]\:
    #
    #   * `KmsMasterKeyId` - The ID of an AWS-managed customer master key
    #     (CMK) for Amazon SNS or a custom CMK. For more information, see [Key
    #     Terms][2]. For more examples, see [KeyId][3] in the *AWS Key
    #     Management Service API Reference*.
    #
    #   ^
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #
    # @option params [Array<Types::Tag>] :tags
    #   The list of tags to add to a new topic.
    #
    #   <note markdown="1"> To be able to tag a topic on creation, you must have the
    #   `sns:CreateTopic` and `sns:TagResource` permissions.
    #
    #    </note>
    #
    # @return [Types::CreateTopicResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateTopicResponse#topic_arn #topic_arn} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_topic({
    #     name: "topicName", # required
    #     attributes: {
    #       "attributeName" => "attributeValue",
    #     },
    #     tags: [
    #       {
    #         key: "TagKey", # required
    #         value: "TagValue", # required
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.topic_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateTopic AWS API Documentation
    #
    # @overload create_topic(params = {})
    # @param [Hash] params ({})
    def create_topic(params = {}, options = {})
      req = build_request(:create_topic, params)
      req.send_request(options)
    end

    # Deletes the endpoint for a device and mobile app from Amazon SNS. This
    # action is idempotent. For more information, see [Using Amazon SNS
    # Mobile Push Notifications][1].
    #
    # When you delete an endpoint that is also subscribed to a topic, then
    # you must also unsubscribe the endpoint from the topic.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :endpoint_arn
    #   EndpointArn of endpoint to delete.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_endpoint({
    #     endpoint_arn: "String", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteEndpoint AWS API Documentation
    #
    # @overload delete_endpoint(params = {})
    # @param [Hash] params ({})
    def delete_endpoint(params = {}, options = {})
      req = build_request(:delete_endpoint, params)
      req.send_request(options)
    end

    # Deletes a platform application object for one of the supported push
    # notification services, such as APNS and GCM (Firebase Cloud
    # Messaging). For more information, see [Using Amazon SNS Mobile Push
    # Notifications][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :platform_application_arn
    #   PlatformApplicationArn of platform application object to delete.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_platform_application({
    #     platform_application_arn: "String", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeletePlatformApplication AWS API Documentation
    #
    # @overload delete_platform_application(params = {})
    # @param [Hash] params ({})
    def delete_platform_application(params = {}, options = {})
      req = build_request(:delete_platform_application, params)
      req.send_request(options)
    end

    # Deletes a topic and all its subscriptions. Deleting a topic might
    # prevent some messages previously sent to the topic from being
    # delivered to subscribers. This action is idempotent, so deleting a
    # topic that does not exist does not result in an error.
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic you want to delete.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_topic({
    #     topic_arn: "topicARN", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteTopic AWS API Documentation
    #
    # @overload delete_topic(params = {})
    # @param [Hash] params ({})
    def delete_topic(params = {}, options = {})
      req = build_request(:delete_topic, params)
      req.send_request(options)
    end

    # Retrieves the endpoint attributes for a device on one of the supported
    # push notification services, such as GCM (Firebase Cloud Messaging) and
    # APNS. For more information, see [Using Amazon SNS Mobile Push
    # Notifications][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :endpoint_arn
    #   EndpointArn for GetEndpointAttributes input.
    #
    # @return [Types::GetEndpointAttributesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetEndpointAttributesResponse#attributes #attributes} => Hash&lt;String,String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_endpoint_attributes({
    #     endpoint_arn: "String", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.attributes #=> Hash
    #   resp.attributes["String"] #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetEndpointAttributes AWS API Documentation
    #
    # @overload get_endpoint_attributes(params = {})
    # @param [Hash] params ({})
    def get_endpoint_attributes(params = {}, options = {})
      req = build_request(:get_endpoint_attributes, params)
      req.send_request(options)
    end

    # Retrieves the attributes of the platform application object for the
    # supported push notification services, such as APNS and GCM (Firebase
    # Cloud Messaging). For more information, see [Using Amazon SNS Mobile
    # Push Notifications][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :platform_application_arn
    #   PlatformApplicationArn for GetPlatformApplicationAttributesInput.
    #
    # @return [Types::GetPlatformApplicationAttributesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetPlatformApplicationAttributesResponse#attributes #attributes} => Hash&lt;String,String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_platform_application_attributes({
    #     platform_application_arn: "String", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.attributes #=> Hash
    #   resp.attributes["String"] #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetPlatformApplicationAttributes AWS API Documentation
    #
    # @overload get_platform_application_attributes(params = {})
    # @param [Hash] params ({})
    def get_platform_application_attributes(params = {}, options = {})
      req = build_request(:get_platform_application_attributes, params)
      req.send_request(options)
    end

    # Returns the settings for sending SMS messages from your account.
    #
    # These settings are set with the `SetSMSAttributes` action.
    #
    # @option params [Array<String>] :attributes
    #   A list of the individual attribute names, such as `MonthlySpendLimit`,
    #   for which you want values.
    #
    #   For all attribute names, see [SetSMSAttributes][1].
    #
    #   If you don't use this parameter, Amazon SNS returns all SMS
    #   attributes.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html
    #
    # @return [Types::GetSMSAttributesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetSMSAttributesResponse#attributes #attributes} => Hash&lt;String,String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_sms_attributes({
    #     attributes: ["String"],
    #   })
    #
    # @example Response structure
    #
    #   resp.attributes #=> Hash
    #   resp.attributes["String"] #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSMSAttributes AWS API Documentation
    #
    # @overload get_sms_attributes(params = {})
    # @param [Hash] params ({})
    def get_sms_attributes(params = {}, options = {})
      req = build_request(:get_sms_attributes, params)
      req.send_request(options)
    end

    # Returns all of the properties of a subscription.
    #
    # @option params [required, String] :subscription_arn
    #   The ARN of the subscription whose properties you want to get.
    #
    # @return [Types::GetSubscriptionAttributesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetSubscriptionAttributesResponse#attributes #attributes} => Hash&lt;String,String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_subscription_attributes({
    #     subscription_arn: "subscriptionARN", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.attributes #=> Hash
    #   resp.attributes["attributeName"] #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSubscriptionAttributes AWS API Documentation
    #
    # @overload get_subscription_attributes(params = {})
    # @param [Hash] params ({})
    def get_subscription_attributes(params = {}, options = {})
      req = build_request(:get_subscription_attributes, params)
      req.send_request(options)
    end

    # Returns all of the properties of a topic. Topic properties returned
    # might differ based on the authorization of the user.
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic whose properties you want to get.
    #
    # @return [Types::GetTopicAttributesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetTopicAttributesResponse#attributes #attributes} => Hash&lt;String,String&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_topic_attributes({
    #     topic_arn: "topicARN", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.attributes #=> Hash
    #   resp.attributes["attributeName"] #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetTopicAttributes AWS API Documentation
    #
    # @overload get_topic_attributes(params = {})
    # @param [Hash] params ({})
    def get_topic_attributes(params = {}, options = {})
      req = build_request(:get_topic_attributes, params)
      req.send_request(options)
    end

    # Lists the endpoints and endpoint attributes for devices in a supported
    # push notification service, such as GCM (Firebase Cloud Messaging) and
    # APNS. The results for `ListEndpointsByPlatformApplication` are
    # paginated and return a limited list of endpoints, up to 100. If
    # additional records are available after the first page results, then a
    # NextToken string will be returned. To receive the next page, you call
    # `ListEndpointsByPlatformApplication` again using the NextToken string
    # received from the previous call. When there are no more records to
    # return, NextToken will be null. For more information, see [Using
    # Amazon SNS Mobile Push Notifications][1].
    #
    # This action is throttled at 30 transactions per second (TPS).
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :platform_application_arn
    #   PlatformApplicationArn for ListEndpointsByPlatformApplicationInput
    #   action.
    #
    # @option params [String] :next_token
    #   NextToken string is used when calling
    #   ListEndpointsByPlatformApplication action to retrieve additional
    #   records that are available after the first page results.
    #
    # @return [Types::ListEndpointsByPlatformApplicationResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListEndpointsByPlatformApplicationResponse#endpoints #endpoints} => Array&lt;Types::Endpoint&gt;
    #   * {Types::ListEndpointsByPlatformApplicationResponse#next_token #next_token} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_endpoints_by_platform_application({
    #     platform_application_arn: "String", # required
    #     next_token: "String",
    #   })
    #
    # @example Response structure
    #
    #   resp.endpoints #=> Array
    #   resp.endpoints[0].endpoint_arn #=> String
    #   resp.endpoints[0].attributes #=> Hash
    #   resp.endpoints[0].attributes["String"] #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListEndpointsByPlatformApplication AWS API Documentation
    #
    # @overload list_endpoints_by_platform_application(params = {})
    # @param [Hash] params ({})
    def list_endpoints_by_platform_application(params = {}, options = {})
      req = build_request(:list_endpoints_by_platform_application, params)
      req.send_request(options)
    end

    # Returns a list of phone numbers that are opted out, meaning you cannot
    # send SMS messages to them.
    #
    # The results for `ListPhoneNumbersOptedOut` are paginated, and each
    # page returns up to 100 phone numbers. If additional phone numbers are
    # available after the first page of results, then a `NextToken` string
    # will be returned. To receive the next page, you call
    # `ListPhoneNumbersOptedOut` again using the `NextToken` string received
    # from the previous call. When there are no more records to return,
    # `NextToken` will be null.
    #
    # @option params [String] :next_token
    #   A `NextToken` string is used when you call the
    #   `ListPhoneNumbersOptedOut` action to retrieve additional records that
    #   are available after the first page of results.
    #
    # @return [Types::ListPhoneNumbersOptedOutResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListPhoneNumbersOptedOutResponse#phone_numbers #phone_numbers} => Array&lt;String&gt;
    #   * {Types::ListPhoneNumbersOptedOutResponse#next_token #next_token} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_phone_numbers_opted_out({
    #     next_token: "string",
    #   })
    #
    # @example Response structure
    #
    #   resp.phone_numbers #=> Array
    #   resp.phone_numbers[0] #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPhoneNumbersOptedOut AWS API Documentation
    #
    # @overload list_phone_numbers_opted_out(params = {})
    # @param [Hash] params ({})
    def list_phone_numbers_opted_out(params = {}, options = {})
      req = build_request(:list_phone_numbers_opted_out, params)
      req.send_request(options)
    end

    # Lists the platform application objects for the supported push
    # notification services, such as APNS and GCM (Firebase Cloud
    # Messaging). The results for `ListPlatformApplications` are paginated
    # and return a limited list of applications, up to 100. If additional
    # records are available after the first page results, then a NextToken
    # string will be returned. To receive the next page, you call
    # `ListPlatformApplications` using the NextToken string received from
    # the previous call. When there are no more records to return,
    # `NextToken` will be null. For more information, see [Using Amazon SNS
    # Mobile Push Notifications][1].
    #
    # This action is throttled at 15 transactions per second (TPS).
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [String] :next_token
    #   NextToken string is used when calling ListPlatformApplications action
    #   to retrieve additional records that are available after the first page
    #   results.
    #
    # @return [Types::ListPlatformApplicationsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListPlatformApplicationsResponse#platform_applications #platform_applications} => Array&lt;Types::PlatformApplication&gt;
    #   * {Types::ListPlatformApplicationsResponse#next_token #next_token} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_platform_applications({
    #     next_token: "String",
    #   })
    #
    # @example Response structure
    #
    #   resp.platform_applications #=> Array
    #   resp.platform_applications[0].platform_application_arn #=> String
    #   resp.platform_applications[0].attributes #=> Hash
    #   resp.platform_applications[0].attributes["String"] #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPlatformApplications AWS API Documentation
    #
    # @overload list_platform_applications(params = {})
    # @param [Hash] params ({})
    def list_platform_applications(params = {}, options = {})
      req = build_request(:list_platform_applications, params)
      req.send_request(options)
    end

    # Returns a list of the requester's subscriptions. Each call returns a
    # limited list of subscriptions, up to 100. If there are more
    # subscriptions, a `NextToken` is also returned. Use the `NextToken`
    # parameter in a new `ListSubscriptions` call to get further results.
    #
    # This action is throttled at 30 transactions per second (TPS).
    #
    # @option params [String] :next_token
    #   Token returned by the previous `ListSubscriptions` request.
    #
    # @return [Types::ListSubscriptionsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListSubscriptionsResponse#subscriptions #subscriptions} => Array&lt;Types::Subscription&gt;
    #   * {Types::ListSubscriptionsResponse#next_token #next_token} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_subscriptions({
    #     next_token: "nextToken",
    #   })
    #
    # @example Response structure
    #
    #   resp.subscriptions #=> Array
    #   resp.subscriptions[0].subscription_arn #=> String
    #   resp.subscriptions[0].owner #=> String
    #   resp.subscriptions[0].protocol #=> String
    #   resp.subscriptions[0].endpoint #=> String
    #   resp.subscriptions[0].topic_arn #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptions AWS API Documentation
    #
    # @overload list_subscriptions(params = {})
    # @param [Hash] params ({})
    def list_subscriptions(params = {}, options = {})
      req = build_request(:list_subscriptions, params)
      req.send_request(options)
    end

    # Returns a list of the subscriptions to a specific topic. Each call
    # returns a limited list of subscriptions, up to 100. If there are more
    # subscriptions, a `NextToken` is also returned. Use the `NextToken`
    # parameter in a new `ListSubscriptionsByTopic` call to get further
    # results.
    #
    # This action is throttled at 30 transactions per second (TPS).
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic for which you wish to find subscriptions.
    #
    # @option params [String] :next_token
    #   Token returned by the previous `ListSubscriptionsByTopic` request.
    #
    # @return [Types::ListSubscriptionsByTopicResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListSubscriptionsByTopicResponse#subscriptions #subscriptions} => Array&lt;Types::Subscription&gt;
    #   * {Types::ListSubscriptionsByTopicResponse#next_token #next_token} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_subscriptions_by_topic({
    #     topic_arn: "topicARN", # required
    #     next_token: "nextToken",
    #   })
    #
    # @example Response structure
    #
    #   resp.subscriptions #=> Array
    #   resp.subscriptions[0].subscription_arn #=> String
    #   resp.subscriptions[0].owner #=> String
    #   resp.subscriptions[0].protocol #=> String
    #   resp.subscriptions[0].endpoint #=> String
    #   resp.subscriptions[0].topic_arn #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptionsByTopic AWS API Documentation
    #
    # @overload list_subscriptions_by_topic(params = {})
    # @param [Hash] params ({})
    def list_subscriptions_by_topic(params = {}, options = {})
      req = build_request(:list_subscriptions_by_topic, params)
      req.send_request(options)
    end

    # List all tags added to the specified Amazon SNS topic. For an
    # overview, see [Amazon SNS Tags][1] in the *Amazon Simple Notification
    # Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html
    #
    # @option params [required, String] :resource_arn
    #   The ARN of the topic for which to list tags.
    #
    # @return [Types::ListTagsForResourceResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListTagsForResourceResponse#tags #tags} => Array&lt;Types::Tag&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_tags_for_resource({
    #     resource_arn: "AmazonResourceName", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.tags #=> Array
    #   resp.tags[0].key #=> String
    #   resp.tags[0].value #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTagsForResource AWS API Documentation
    #
    # @overload list_tags_for_resource(params = {})
    # @param [Hash] params ({})
    def list_tags_for_resource(params = {}, options = {})
      req = build_request(:list_tags_for_resource, params)
      req.send_request(options)
    end

    # Returns a list of the requester's topics. Each call returns a limited
    # list of topics, up to 100. If there are more topics, a `NextToken` is
    # also returned. Use the `NextToken` parameter in a new `ListTopics`
    # call to get further results.
    #
    # This action is throttled at 30 transactions per second (TPS).
    #
    # @option params [String] :next_token
    #   Token returned by the previous `ListTopics` request.
    #
    # @return [Types::ListTopicsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListTopicsResponse#topics #topics} => Array&lt;Types::Topic&gt;
    #   * {Types::ListTopicsResponse#next_token #next_token} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_topics({
    #     next_token: "nextToken",
    #   })
    #
    # @example Response structure
    #
    #   resp.topics #=> Array
    #   resp.topics[0].topic_arn #=> String
    #   resp.next_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTopics AWS API Documentation
    #
    # @overload list_topics(params = {})
    # @param [Hash] params ({})
    def list_topics(params = {}, options = {})
      req = build_request(:list_topics, params)
      req.send_request(options)
    end

    # Use this request to opt in a phone number that is opted out, which
    # enables you to resume sending SMS messages to the number.
    #
    # You can opt in a phone number only once every 30 days.
    #
    # @option params [required, String] :phone_number
    #   The phone number to opt in.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.opt_in_phone_number({
    #     phone_number: "PhoneNumber", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/OptInPhoneNumber AWS API Documentation
    #
    # @overload opt_in_phone_number(params = {})
    # @param [Hash] params ({})
    def opt_in_phone_number(params = {}, options = {})
      req = build_request(:opt_in_phone_number, params)
      req.send_request(options)
    end

    # Sends a message to an Amazon SNS topic, a text message (SMS message)
    # directly to a phone number, or a message to a mobile platform endpoint
    # (when you specify the `TargetArn`).
    #
    # If you send a message to a topic, Amazon SNS delivers the message to
    # each endpoint that is subscribed to the topic. The format of the
    # message depends on the notification protocol for each subscribed
    # endpoint.
    #
    # When a `messageId` is returned, the message has been saved and Amazon
    # SNS will attempt to deliver it shortly.
    #
    # To use the `Publish` action for sending a message to a mobile
    # endpoint, such as an app on a Kindle device or mobile phone, you must
    # specify the EndpointArn for the TargetArn parameter. The EndpointArn
    # is returned when making a call with the `CreatePlatformEndpoint`
    # action.
    #
    # For more information about formatting messages, see [Send Custom
    # Platform-Specific Payloads in Messages to Mobile Devices][1].
    #
    # You can publish messages only to topics and endpoints in the same AWS
    # Region.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html
    #
    # @option params [String] :topic_arn
    #   The topic you want to publish to.
    #
    #   If you don't specify a value for the `TopicArn` parameter, you must
    #   specify a value for the `PhoneNumber` or `TargetArn` parameters.
    #
    # @option params [String] :target_arn
    #   If you don't specify a value for the `TargetArn` parameter, you must
    #   specify a value for the `PhoneNumber` or `TopicArn` parameters.
    #
    # @option params [String] :phone_number
    #   The phone number to which you want to deliver an SMS message. Use
    #   E.164 format.
    #
    #   If you don't specify a value for the `PhoneNumber` parameter, you
    #   must specify a value for the `TargetArn` or `TopicArn` parameters.
    #
    # @option params [required, String] :message
    #   The message you want to send.
    #
    #   If you are publishing to a topic and you want to send the same message
    #   to all transport protocols, include the text of the message as a
    #   String value. If you want to send different messages for each
    #   transport protocol, set the value of the `MessageStructure` parameter
    #   to `json` and use a JSON object for the `Message` parameter.
    #
    #
    #
    #   Constraints:
    #
    #   * With the exception of SMS, messages must be UTF-8 encoded strings
    #     and at most 256 KB in size (262,144 bytes, not 262,144 characters).
    #
    #   * For SMS, each message can contain up to 140 characters. This
    #     character limit depends on the encoding schema. For example, an SMS
    #     message can contain 160 GSM characters, 140 ASCII characters, or 70
    #     UCS-2 characters.
    #
    #     If you publish a message that exceeds this size limit, Amazon SNS
    #     sends the message as multiple messages, each fitting within the size
    #     limit. Messages aren't truncated mid-word but are cut off at
    #     whole-word boundaries.
    #
    #     The total size limit for a single SMS `Publish` action is 1,600
    #     characters.
    #
    #   JSON-specific constraints:
    #
    #   * Keys in the JSON object that correspond to supported transport
    #     protocols must have simple JSON string values.
    #
    #   * The values will be parsed (unescaped) before they are used in
    #     outgoing messages.
    #
    #   * Outbound notifications are JSON encoded (meaning that the characters
    #     will be reescaped for sending).
    #
    #   * Values have a minimum length of 0 (the empty string, "", is
    #     allowed).
    #
    #   * Values have a maximum length bounded by the overall message size
    #     (so, including multiple protocols may limit message sizes).
    #
    #   * Non-string values will cause the key to be ignored.
    #
    #   * Keys that do not correspond to supported transport protocols are
    #     ignored.
    #
    #   * Duplicate keys are not allowed.
    #
    #   * Failure to parse or validate any key or value in the message will
    #     cause the `Publish` call to return an error (no partial delivery).
    #
    # @option params [String] :subject
    #   Optional parameter to be used as the "Subject" line when the message
    #   is delivered to email endpoints. This field will also be included, if
    #   present, in the standard JSON messages delivered to other endpoints.
    #
    #   Constraints: Subjects must be ASCII text that begins with a letter,
    #   number, or punctuation mark; must not include line breaks or control
    #   characters; and must be less than 100 characters long.
    #
    # @option params [String] :message_structure
    #   Set `MessageStructure` to `json` if you want to send a different
    #   message for each protocol. For example, using one publish action, you
    #   can send a short message to your SMS subscribers and a longer message
    #   to your email subscribers. If you set `MessageStructure` to `json`,
    #   the value of the `Message` parameter must:
    #
    #   * be a syntactically valid JSON object; and
    #
    #   * contain at least a top-level JSON key of "default" with a value
    #     that is a string.
    #
    #   You can define other top-level keys that define the message you want
    #   to send to a specific transport protocol (e.g., "http").
    #
    #   Valid value: `json`
    #
    # @option params [Hash<String,Types::MessageAttributeValue>] :message_attributes
    #   Message attributes for Publish action.
    #
    # @return [Types::PublishResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PublishResponse#message_id #message_id} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.publish({
    #     topic_arn: "topicARN",
    #     target_arn: "String",
    #     phone_number: "String",
    #     message: "message", # required
    #     subject: "subject",
    #     message_structure: "messageStructure",
    #     message_attributes: {
    #       "String" => {
    #         data_type: "String", # required
    #         string_value: "String",
    #         binary_value: "data",
    #       },
    #     },
    #   })
    #
    # @example Response structure
    #
    #   resp.message_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Publish AWS API Documentation
    #
    # @overload publish(params = {})
    # @param [Hash] params ({})
    def publish(params = {}, options = {})
      req = build_request(:publish, params)
      req.send_request(options)
    end

    # Removes a statement from a topic's access control policy.
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic whose access control policy you wish to modify.
    #
    # @option params [required, String] :label
    #   The unique label of the statement you want to remove.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.remove_permission({
    #     topic_arn: "topicARN", # required
    #     label: "label", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/RemovePermission AWS API Documentation
    #
    # @overload remove_permission(params = {})
    # @param [Hash] params ({})
    def remove_permission(params = {}, options = {})
      req = build_request(:remove_permission, params)
      req.send_request(options)
    end

    # Sets the attributes for an endpoint for a device on one of the
    # supported push notification services, such as GCM (Firebase Cloud
    # Messaging) and APNS. For more information, see [Using Amazon SNS
    # Mobile Push Notifications][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    #
    # @option params [required, String] :endpoint_arn
    #   EndpointArn used for SetEndpointAttributes action.
    #
    # @option params [required, Hash<String,String>] :attributes
    #   A map of the endpoint attributes. Attributes in this map include the
    #   following:
    #
    #   * `CustomUserData` – arbitrary user data to associate with the
    #     endpoint. Amazon SNS does not use this data. The data must be in
    #     UTF-8 format and less than 2KB.
    #
    #   * `Enabled` – flag that enables/disables delivery to the endpoint.
    #     Amazon SNS will set this to false when a notification service
    #     indicates to Amazon SNS that the endpoint is invalid. Users can set
    #     it back to true, typically after updating Token.
    #
    #   * `Token` – device token, also referred to as a registration id, for
    #     an app and mobile device. This is returned from the notification
    #     service when an app and mobile device are registered with the
    #     notification service.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.set_endpoint_attributes({
    #     endpoint_arn: "String", # required
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetEndpointAttributes AWS API Documentation
    #
    # @overload set_endpoint_attributes(params = {})
    # @param [Hash] params ({})
    def set_endpoint_attributes(params = {}, options = {})
      req = build_request(:set_endpoint_attributes, params)
      req.send_request(options)
    end

    # Sets the attributes of the platform application object for the
    # supported push notification services, such as APNS and GCM (Firebase
    # Cloud Messaging). For more information, see [Using Amazon SNS Mobile
    # Push Notifications][1]. For information on configuring attributes for
    # message delivery status, see [Using Amazon SNS Application Attributes
    # for Message Delivery Status][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html
    #
    # @option params [required, String] :platform_application_arn
    #   PlatformApplicationArn for SetPlatformApplicationAttributes action.
    #
    # @option params [required, Hash<String,String>] :attributes
    #   A map of the platform application attributes. Attributes in this map
    #   include the following:
    #
    #   * `PlatformCredential` – The credential received from the notification
    #     service. For `APNS` and `APNS_SANDBOX`, `PlatformCredential` is
    #     `private key`. For `GCM` (Firebase Cloud Messaging),
    #     `PlatformCredential` is `API key`. For `ADM`, `PlatformCredential`
    #     is `client secret`.
    #
    #   * `PlatformPrincipal` – The principal received from the notification
    #     service. For `APNS` and `APNS_SANDBOX`, `PlatformPrincipal` is `SSL
    #     certificate`. For `GCM` (Firebase Cloud Messaging), there is no
    #     `PlatformPrincipal`. For `ADM`, `PlatformPrincipal` is `client id`.
    #
    #   * `EventEndpointCreated` – Topic ARN to which `EndpointCreated` event
    #     notifications are sent.
    #
    #   * `EventEndpointDeleted` – Topic ARN to which `EndpointDeleted` event
    #     notifications are sent.
    #
    #   * `EventEndpointUpdated` – Topic ARN to which `EndpointUpdate` event
    #     notifications are sent.
    #
    #   * `EventDeliveryFailure` – Topic ARN to which `DeliveryFailure` event
    #     notifications are sent upon Direct Publish delivery failure
    #     (permanent) to one of the application's endpoints.
    #
    #   * `SuccessFeedbackRoleArn` – IAM role ARN used to give Amazon SNS
    #     write access to use CloudWatch Logs on your behalf.
    #
    #   * `FailureFeedbackRoleArn` – IAM role ARN used to give Amazon SNS
    #     write access to use CloudWatch Logs on your behalf.
    #
    #   * `SuccessFeedbackSampleRate` – Sample rate percentage (0-100) of
    #     successfully delivered messages.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.set_platform_application_attributes({
    #     platform_application_arn: "String", # required
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetPlatformApplicationAttributes AWS API Documentation
    #
    # @overload set_platform_application_attributes(params = {})
    # @param [Hash] params ({})
    def set_platform_application_attributes(params = {}, options = {})
      req = build_request(:set_platform_application_attributes, params)
      req.send_request(options)
    end

    # Use this request to set the default settings for sending SMS messages
    # and receiving daily SMS usage reports.
    #
    # You can override some of these settings for a single message when you
    # use the `Publish` action with the `MessageAttributes.entry.N`
    # parameter. For more information, see [Sending an SMS Message][1] in
    # the *Amazon SNS Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html
    #
    # @option params [required, Hash<String,String>] :attributes
    #   The default settings for sending SMS messages from your account. You
    #   can set values for the following attribute names:
    #
    #   `MonthlySpendLimit` – The maximum amount in USD that you are willing
    #   to spend each month to send SMS messages. When Amazon SNS determines
    #   that sending an SMS message would incur a cost that exceeds this
    #   limit, it stops sending SMS messages within minutes.
    #
    #   Amazon SNS stops sending SMS messages within minutes of the limit
    #   being crossed. During that interval, if you continue to send SMS
    #   messages, you will incur costs that exceed your limit.
    #
    #   By default, the spend limit is set to the maximum allowed by Amazon
    #   SNS. If you want to raise the limit, submit an [SNS Limit Increase
    #   case][1]. For **New limit value**, enter your desired monthly spend
    #   limit. In the **Use Case Description** field, explain that you are
    #   requesting an SMS monthly spend limit increase.
    #
    #   `DeliveryStatusIAMRole` – The ARN of the IAM role that allows Amazon
    #   SNS to write logs about SMS deliveries in CloudWatch Logs. For each
    #   SMS message that you send, Amazon SNS writes a log that includes the
    #   message price, the success or failure status, the reason for failure
    #   (if the message failed), the message dwell time, and other
    #   information.
    #
    #   `DeliveryStatusSuccessSamplingRate` – The percentage of successful SMS
    #   deliveries for which Amazon SNS will write logs in CloudWatch Logs.
    #   The value can be an integer from 0 - 100. For example, to write logs
    #   only for failed deliveries, set this value to `0`. To write logs for
    #   10% of your successful deliveries, set it to `10`.
    #
    #   `DefaultSenderID` – A string, such as your business brand, that is
    #   displayed as the sender on the receiving device. Support for sender
    #   IDs varies by country. The sender ID can be 1 - 11 alphanumeric
    #   characters, and it must contain at least one letter.
    #
    #   `DefaultSMSType` – The type of SMS message that you will send by
    #   default. You can assign the following values:
    #
    #   * `Promotional` – (Default) Noncritical messages, such as marketing
    #     messages. Amazon SNS optimizes the message delivery to incur the
    #     lowest cost.
    #
    #   * `Transactional` – Critical messages that support customer
    #     transactions, such as one-time passcodes for multi-factor
    #     authentication. Amazon SNS optimizes the message delivery to achieve
    #     the highest reliability.
    #
    #   `UsageReportS3Bucket` – The name of the Amazon S3 bucket to receive
    #   daily SMS usage reports from Amazon SNS. Each day, Amazon SNS will
    #   deliver a usage report as a CSV file to the bucket. The report
    #   includes the following information for each SMS message that was
    #   successfully delivered by your account:
    #
    #   * Time that the message was published (in UTC)
    #
    #   * Message ID
    #
    #   * Destination phone number
    #
    #   * Message type
    #
    #   * Delivery status
    #
    #   * Message price (in USD)
    #
    #   * Part number (a message is split into multiple parts if it is too
    #     long for a single message)
    #
    #   * Total number of parts
    #
    #   To receive the report, the bucket must have a policy that allows the
    #   Amazon SNS service principle to perform the `s3:PutObject` and
    #   `s3:GetBucketLocation` actions.
    #
    #   For an example bucket policy and usage report, see [Monitoring SMS
    #   Activity][2] in the *Amazon SNS Developer Guide*.
    #
    #
    #
    #   [1]: https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sns
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sms_stats.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.set_sms_attributes({
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetSMSAttributes AWS API Documentation
    #
    # @overload set_sms_attributes(params = {})
    # @param [Hash] params ({})
    def set_sms_attributes(params = {}, options = {})
      req = build_request(:set_sms_attributes, params)
      req.send_request(options)
    end

    # Allows a subscription owner to set an attribute of the subscription to
    # a new value.
    #
    # @option params [required, String] :subscription_arn
    #   The ARN of the subscription to modify.
    #
    # @option params [required, String] :attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `SetTopicAttributes` action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `FilterPolicy` – The simple JSON object that lets your subscriber
    #     receive only a subset of messages, rather than receiving every
    #     message published to the topic.
    #
    #   * `RawMessageDelivery` – When set to `true`, enables raw message
    #     delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need
    #     for the endpoints to process JSON formatting, which is otherwise
    #     created for Amazon SNS metadata.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't be
    #     delivered due to client errors (for example, when the subscribed
    #     endpoint is unreachable) or server errors (for example, when the
    #     service that powers the subscribed endpoint becomes unavailable) are
    #     held in the dead-letter queue for further analysis or reprocessing.
    #
    # @option params [String] :attribute_value
    #   The new value for the attribute in JSON format.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.set_subscription_attributes({
    #     subscription_arn: "subscriptionARN", # required
    #     attribute_name: "attributeName", # required
    #     attribute_value: "attributeValue",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetSubscriptionAttributes AWS API Documentation
    #
    # @overload set_subscription_attributes(params = {})
    # @param [Hash] params ({})
    def set_subscription_attributes(params = {}, options = {})
      req = build_request(:set_subscription_attributes, params)
      req.send_request(options)
    end

    # Allows a topic owner to set an attribute of the topic to a new value.
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic to modify.
    #
    # @option params [required, String] :attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `SetTopicAttributes` action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `DisplayName` – The display name to use for a topic with SMS
    #     subscriptions.
    #
    #   * `Policy` – The policy that defines who can access your topic. By
    #     default, only the topic owner can publish or subscribe to the topic.
    #
    #   The following attribute applies only to [server-side-encryption][1]\:
    #
    #   * `KmsMasterKeyId` - The ID of an AWS-managed customer master key
    #     (CMK) for Amazon SNS or a custom CMK. For more information, see [Key
    #     Terms][2]. For more examples, see [KeyId][3] in the *AWS Key
    #     Management Service API Reference*.
    #
    #   ^
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #
    # @option params [String] :attribute_value
    #   The new value for the attribute.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.set_topic_attributes({
    #     topic_arn: "topicARN", # required
    #     attribute_name: "attributeName", # required
    #     attribute_value: "attributeValue",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetTopicAttributes AWS API Documentation
    #
    # @overload set_topic_attributes(params = {})
    # @param [Hash] params ({})
    def set_topic_attributes(params = {}, options = {})
      req = build_request(:set_topic_attributes, params)
      req.send_request(options)
    end

    # Subscribes an endpoint to an Amazon SNS topic. If the endpoint type is
    # HTTP/S or email, or if the endpoint and the topic are not in the same
    # AWS account, the endpoint owner must the `ConfirmSubscription` action
    # to confirm the subscription.
    #
    # You call the `ConfirmSubscription` action with the token from the
    # subscription response. Confirmation tokens are valid for three days.
    #
    # This action is throttled at 100 transactions per second (TPS).
    #
    # @option params [required, String] :topic_arn
    #   The ARN of the topic you want to subscribe to.
    #
    # @option params [required, String] :protocol
    #   The protocol you want to use. Supported protocols include:
    #
    #   * `http` – delivery of JSON-encoded message via HTTP POST
    #
    #   * `https` – delivery of JSON-encoded message via HTTPS POST
    #
    #   * `email` – delivery of message via SMTP
    #
    #   * `email-json` – delivery of JSON-encoded message via SMTP
    #
    #   * `sms` – delivery of message via SMS
    #
    #   * `sqs` – delivery of JSON-encoded message to an Amazon SQS queue
    #
    #   * `application` – delivery of JSON-encoded message to an EndpointArn
    #     for a mobile app and device.
    #
    #   * `lambda` – delivery of JSON-encoded message to an Amazon Lambda
    #     function.
    #
    # @option params [String] :endpoint
    #   The endpoint that you want to receive notifications. Endpoints vary by
    #   protocol:
    #
    #   * For the `http` protocol, the (public) endpoint is a URL beginning
    #     with `http://`
    #
    #   * For the `https` protocol, the (public) endpoint is a URL beginning
    #     with `https://`
    #
    #   * For the `email` protocol, the endpoint is an email address
    #
    #   * For the `email-json` protocol, the endpoint is an email address
    #
    #   * For the `sms` protocol, the endpoint is a phone number of an
    #     SMS-enabled device
    #
    #   * For the `sqs` protocol, the endpoint is the ARN of an Amazon SQS
    #     queue
    #
    #   * For the `application` protocol, the endpoint is the EndpointArn of a
    #     mobile app and device.
    #
    #   * For the `lambda` protocol, the endpoint is the ARN of an Amazon
    #     Lambda function.
    #
    # @option params [Hash<String,String>] :attributes
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `SetTopicAttributes` action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `FilterPolicy` – The simple JSON object that lets your subscriber
    #     receive only a subset of messages, rather than receiving every
    #     message published to the topic.
    #
    #   * `RawMessageDelivery` – When set to `true`, enables raw message
    #     delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need
    #     for the endpoints to process JSON formatting, which is otherwise
    #     created for Amazon SNS metadata.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't be
    #     delivered due to client errors (for example, when the subscribed
    #     endpoint is unreachable) or server errors (for example, when the
    #     service that powers the subscribed endpoint becomes unavailable) are
    #     held in the dead-letter queue for further analysis or reprocessing.
    #
    # @option params [Boolean] :return_subscription_arn
    #   Sets whether the response from the `Subscribe` request includes the
    #   subscription ARN, even if the subscription is not yet confirmed.
    #
    #   * If you set this parameter to `true`, the response includes the ARN
    #     in all cases, even if the subscription is not yet confirmed. In
    #     addition to the ARN for confirmed subscriptions, the response also
    #     includes the `pending subscription` ARN value for subscriptions that
    #     aren't yet confirmed. A subscription becomes confirmed when the
    #     subscriber calls the `ConfirmSubscription` action with a
    #     confirmation token.
    #
    #   ^
    #
    #
    #
    #   The default value is `false`.
    #
    # @return [Types::SubscribeResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::SubscribeResponse#subscription_arn #subscription_arn} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.subscribe({
    #     topic_arn: "topicARN", # required
    #     protocol: "protocol", # required
    #     endpoint: "endpoint",
    #     attributes: {
    #       "attributeName" => "attributeValue",
    #     },
    #     return_subscription_arn: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.subscription_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Subscribe AWS API Documentation
    #
    # @overload subscribe(params = {})
    # @param [Hash] params ({})
    def subscribe(params = {}, options = {})
      req = build_request(:subscribe, params)
      req.send_request(options)
    end

    # Add tags to the specified Amazon SNS topic. For an overview, see
    # [Amazon SNS Tags][1] in the *Amazon SNS Developer Guide*.
    #
    # When you use topic tags, keep the following guidelines in mind:
    #
    # * Adding more than 50 tags to a topic isn't recommended.
    #
    # * Tags don't have any semantic meaning. Amazon SNS interprets tags as
    #   character strings.
    #
    # * Tags are case-sensitive.
    #
    # * A new tag with a key identical to that of an existing tag overwrites
    #   the existing tag.
    #
    # * Tagging actions are limited to 10 TPS per AWS account, per AWS
    #   region. If your application requires a higher throughput, file a
    #   [technical support request][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html
    # [2]: https://console.aws.amazon.com/support/home#/case/create?issueType=technical
    #
    # @option params [required, String] :resource_arn
    #   The ARN of the topic to which to add tags.
    #
    # @option params [required, Array<Types::Tag>] :tags
    #   The tags to be added to the specified topic. A tag consists of a
    #   required key and an optional value.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.tag_resource({
    #     resource_arn: "AmazonResourceName", # required
    #     tags: [ # required
    #       {
    #         key: "TagKey", # required
    #         value: "TagValue", # required
    #       },
    #     ],
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TagResource AWS API Documentation
    #
    # @overload tag_resource(params = {})
    # @param [Hash] params ({})
    def tag_resource(params = {}, options = {})
      req = build_request(:tag_resource, params)
      req.send_request(options)
    end

    # Deletes a subscription. If the subscription requires authentication
    # for deletion, only the owner of the subscription or the topic's owner
    # can unsubscribe, and an AWS signature is required. If the
    # `Unsubscribe` call does not require authentication and the requester
    # is not the subscription owner, a final cancellation message is
    # delivered to the endpoint, so that the endpoint owner can easily
    # resubscribe to the topic if the `Unsubscribe` request was unintended.
    #
    # This action is throttled at 100 transactions per second (TPS).
    #
    # @option params [required, String] :subscription_arn
    #   The ARN of the subscription to be deleted.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.unsubscribe({
    #     subscription_arn: "subscriptionARN", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Unsubscribe AWS API Documentation
    #
    # @overload unsubscribe(params = {})
    # @param [Hash] params ({})
    def unsubscribe(params = {}, options = {})
      req = build_request(:unsubscribe, params)
      req.send_request(options)
    end

    # Remove tags from the specified Amazon SNS topic. For an overview, see
    # [Amazon SNS Tags][1] in the *Amazon SNS Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html
    #
    # @option params [required, String] :resource_arn
    #   The ARN of the topic from which to remove tags.
    #
    # @option params [required, Array<String>] :tag_keys
    #   The list of tag keys to remove from the specified topic.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.untag_resource({
    #     resource_arn: "AmazonResourceName", # required
    #     tag_keys: ["TagKey"], # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/UntagResource AWS API Documentation
    #
    # @overload untag_resource(params = {})
    # @param [Hash] params ({})
    def untag_resource(params = {}, options = {})
      req = build_request(:untag_resource, params)
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
      context[:gem_name] = 'aws-sdk-sns'
      context[:gem_version] = '1.30.0'
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
