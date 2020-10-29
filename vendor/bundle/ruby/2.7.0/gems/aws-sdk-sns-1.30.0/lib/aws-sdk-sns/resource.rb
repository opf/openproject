# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS

  # This class provides a resource oriented interface for SNS.
  # To create a resource object:
  #
  #     resource = Aws::SNS::Resource.new(region: 'us-west-2')
  #
  # You can supply a client object with custom configuration that will be used for all resource operations.
  # If you do not pass `:client`, a default client will be constructed.
  #
  #     client = Aws::SNS::Client.new(region: 'us-west-2')
  #     resource = Aws::SNS::Resource.new(client: client)
  #
  class Resource

    # @param options ({})
    # @option options [Client] :client
    def initialize(options = {})
      @client = options[:client] || Client.new(options)
    end

    # @return [Client]
    def client
      @client
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   platformapplication = sns.create_platform_application({
    #     name: "String", # required
    #     platform: "String", # required
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :name
    #   Application names must be made up of only uppercase and lowercase
    #   ASCII letters, numbers, underscores, hyphens, and periods, and must be
    #   between 1 and 256 characters long.
    # @option options [required, String] :platform
    #   The following platforms are supported: ADM (Amazon Device Messaging),
    #   APNS (Apple Push Notification Service), APNS\_SANDBOX, and GCM
    #   (Firebase Cloud Messaging).
    # @option options [required, Hash<String,String>] :attributes
    #   For a list of attributes, see [SetPlatformApplicationAttributes][1]
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetPlatformApplicationAttributes.html
    # @return [PlatformApplication]
    def create_platform_application(options = {})
      resp = @client.create_platform_application(options)
      PlatformApplication.new(
        arn: resp.data.platform_application_arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   topic = sns.create_topic({
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
    # @param [Hash] options ({})
    # @option options [required, String] :name
    #   The name of the topic you want to create.
    #
    #   Constraints: Topic names must be made up of only uppercase and
    #   lowercase ASCII letters, numbers, underscores, and hyphens, and must
    #   be between 1 and 256 characters long.
    # @option options [Hash<String,String>] :attributes
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
    # @option options [Array<Types::Tag>] :tags
    #   The list of tags to add to a new topic.
    #
    #   <note markdown="1"> To be able to tag a topic on creation, you must have the
    #   `sns:CreateTopic` and `sns:TagResource` permissions.
    #
    #    </note>
    # @return [Topic]
    def create_topic(options = {})
      resp = @client.create_topic(options)
      Topic.new(
        arn: resp.data.topic_arn,
        client: @client
      )
    end

    # @!group Associations

    # @param [String] arn
    # @return [PlatformApplication]
    def platform_application(arn)
      PlatformApplication.new(
        arn: arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   sns.platform_applications()
    # @param [Hash] options ({})
    # @return [PlatformApplication::Collection]
    def platform_applications(options = {})
      batches = Enumerator.new do |y|
        resp = @client.list_platform_applications(options)
        resp.each_page do |page|
          batch = []
          page.data.platform_applications.each do |p|
            batch << PlatformApplication.new(
              arn: p.platform_application_arn,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      PlatformApplication::Collection.new(batches)
    end

    # @param [String] arn
    # @return [PlatformEndpoint]
    def platform_endpoint(arn)
      PlatformEndpoint.new(
        arn: arn,
        client: @client
      )
    end

    # @param [String] arn
    # @return [Subscription]
    def subscription(arn)
      Subscription.new(
        arn: arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   sns.subscriptions()
    # @param [Hash] options ({})
    # @return [Subscription::Collection]
    def subscriptions(options = {})
      batches = Enumerator.new do |y|
        resp = @client.list_subscriptions(options)
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

    # @param [String] arn
    # @return [Topic]
    def topic(arn)
      Topic.new(
        arn: arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   sns.topics()
    # @param [Hash] options ({})
    # @return [Topic::Collection]
    def topics(options = {})
      batches = Enumerator.new do |y|
        resp = @client.list_topics(options)
        resp.each_page do |page|
          batch = []
          page.data.topics.each do |t|
            batch << Topic.new(
              arn: t.topic_arn,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      Topic::Collection.new(batches)
    end

  end
end
