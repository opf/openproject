# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS

  class Topic

    extend Aws::Deprecations

    # @overload def initialize(arn, options = {})
    #   @param [String] arn
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :arn
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @arn = extract_arn(args, options)
      @data = options.delete(:data)
      @client = options.delete(:client) || Client.new(options)
      @waiter_block_warned = false
    end

    # @!group Read-Only Attributes

    # @return [String]
    def arn
      @arn
    end

    # A map of the topic's attributes. Attributes in this map include the
    # following:
    #
    # * `DeliveryPolicy` – The JSON serialization of the topic's delivery
    #   policy.
    #
    # * `DisplayName` – The human-readable name used in the `From` field for
    #   notifications to `email` and `email-json` endpoints.
    #
    # * `Owner` – The AWS account ID of the topic's owner.
    #
    # * `Policy` – The JSON serialization of the topic's access control
    #   policy.
    #
    # * `SubscriptionsConfirmed` – The number of confirmed subscriptions for
    #   the topic.
    #
    # * `SubscriptionsDeleted` – The number of deleted subscriptions for the
    #   topic.
    #
    # * `SubscriptionsPending` – The number of subscriptions pending
    #   confirmation for the topic.
    #
    # * `TopicArn` – The topic's ARN.
    #
    # * `EffectiveDeliveryPolicy` – The JSON serialization of the effective
    #   delivery policy, taking system defaults into account.
    #
    # The following attribute applies only to [server-side-encryption][1]\:
    #
    # * `KmsMasterKeyId` - The ID of an AWS-managed customer master key
    #   (CMK) for Amazon SNS or a custom CMK. For more information, see [Key
    #   Terms][2]. For more examples, see [KeyId][3] in the *AWS Key
    #   Management Service API Reference*.
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    # [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    # @return [Hash<String,String>]
    def attributes
      data[:attributes]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # Loads, or reloads {#data} for the current {Topic}.
    # Returns `self` making it possible to chain methods.
    #
    #     topic.reload.data
    #
    # @return [self]
    def load
      resp = @client.get_topic_attributes(topic_arn: @arn)
      @data = resp.data
      self
    end
    alias :reload :load

    # @return [Types::GetTopicAttributesResponse]
    #   Returns the data for this {Topic}. Calls
    #   {Client#get_topic_attributes} if {#data_loaded?} is `false`.
    def data
      load unless @data
      @data
    end

    # @return [Boolean]
    #   Returns `true` if this resource is loaded.  Accessing attributes or
    #   {#data} on an unloaded resource will trigger a call to {#load}.
    def data_loaded?
      !!@data
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   topic.add_permission({
    #     label: "label", # required
    #     aws_account_id: ["delegate"], # required
    #     action_name: ["action"], # required
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :label
    #   A unique identifier for the new policy statement.
    # @option options [required, Array<String>] :aws_account_id
    #   The AWS account IDs of the users (principals) who will be given access
    #   to the specified actions. The users must have AWS accounts, but do not
    #   need to be signed up for this service.
    # @option options [required, Array<String>] :action_name
    #   The action you want to allow for the specified principal(s).
    #
    #   Valid values: Any Amazon SNS action name, for example `Publish`.
    # @return [EmptyStructure]
    def add_permission(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.add_permission(options)
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   subscription = topic.confirm_subscription({
    #     token: "token", # required
    #     authenticate_on_unsubscribe: "authenticateOnUnsubscribe",
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :token
    #   Short-lived token sent to an endpoint during the `Subscribe` action.
    # @option options [String] :authenticate_on_unsubscribe
    #   Disallows unauthenticated unsubscribes of the subscription. If the
    #   value of this parameter is `true` and the request has an AWS
    #   signature, then only the topic owner and the subscription owner can
    #   unsubscribe the endpoint. The unsubscribe action requires AWS
    #   authentication.
    # @return [Subscription]
    def confirm_subscription(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.confirm_subscription(options)
      Subscription.new(
        arn: resp.data.subscription_arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   topic.delete()
    # @param [Hash] options ({})
    # @return [EmptyStructure]
    def delete(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.delete_topic(options)
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.publish({
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
    # @param [Hash] options ({})
    # @option options [String] :target_arn
    #   If you don't specify a value for the `TargetArn` parameter, you must
    #   specify a value for the `PhoneNumber` or `TopicArn` parameters.
    # @option options [String] :phone_number
    #   The phone number to which you want to deliver an SMS message. Use
    #   E.164 format.
    #
    #   If you don't specify a value for the `PhoneNumber` parameter, you
    #   must specify a value for the `TargetArn` or `TopicArn` parameters.
    # @option options [required, String] :message
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
    # @option options [String] :subject
    #   Optional parameter to be used as the "Subject" line when the message
    #   is delivered to email endpoints. This field will also be included, if
    #   present, in the standard JSON messages delivered to other endpoints.
    #
    #   Constraints: Subjects must be ASCII text that begins with a letter,
    #   number, or punctuation mark; must not include line breaks or control
    #   characters; and must be less than 100 characters long.
    # @option options [String] :message_structure
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
    # @option options [Hash<String,Types::MessageAttributeValue>] :message_attributes
    #   Message attributes for Publish action.
    # @return [Types::PublishResponse]
    def publish(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.publish(options)
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.remove_permission({
    #     label: "label", # required
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :label
    #   The unique label of the statement you want to remove.
    # @return [EmptyStructure]
    def remove_permission(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.remove_permission(options)
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.set_attributes({
    #     attribute_name: "attributeName", # required
    #     attribute_value: "attributeValue",
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :attribute_name
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
    # @option options [String] :attribute_value
    #   The new value for the attribute.
    # @return [EmptyStructure]
    def set_attributes(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.set_topic_attributes(options)
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   subscription = topic.subscribe({
    #     protocol: "protocol", # required
    #     endpoint: "endpoint",
    #     attributes: {
    #       "attributeName" => "attributeValue",
    #     },
    #     return_subscription_arn: false,
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :protocol
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
    # @option options [String] :endpoint
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
    # @option options [Hash<String,String>] :attributes
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
    # @option options [Boolean] :return_subscription_arn
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
    # @return [Subscription]
    def subscribe(options = {})
      options = options.merge(topic_arn: @arn)
      resp = @client.subscribe(options)
      Subscription.new(
        arn: resp.data.subscription_arn,
        client: @client
      )
    end

    # @!group Associations

    # @example Request syntax with placeholder values
    #
    #   topic.subscriptions()
    # @param [Hash] options ({})
    # @return [Subscription::Collection]
    def subscriptions(options = {})
      batches = Enumerator.new do |y|
        options = options.merge(topic_arn: @arn)
        resp = @client.list_subscriptions_by_topic(options)
        resp.each_page do |page|
          batch = []
          page.data.subscriptions.each do |s|
            batch << Subscription.new(
              arn: s.subscription_arn,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      Subscription::Collection.new(batches)
    end

    # @deprecated
    # @api private
    def identifiers
      { arn: @arn }
    end
    deprecated(:identifiers)

    private

    def extract_arn(args, options)
      value = args[0] || options.delete(:arn)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :arn"
      else
        msg = "expected :arn to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    class Collection < Aws::Resources::Collection; end
  end
end
