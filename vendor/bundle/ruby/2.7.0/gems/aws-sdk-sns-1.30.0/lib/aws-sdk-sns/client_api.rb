# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS
  # @api private
  module ClientApi

    include Seahorse::Model

    ActionsList = Shapes::ListShape.new(name: 'ActionsList')
    AddPermissionInput = Shapes::StructureShape.new(name: 'AddPermissionInput')
    AmazonResourceName = Shapes::StringShape.new(name: 'AmazonResourceName')
    AuthorizationErrorException = Shapes::StructureShape.new(name: 'AuthorizationErrorException')
    Binary = Shapes::BlobShape.new(name: 'Binary')
    CheckIfPhoneNumberIsOptedOutInput = Shapes::StructureShape.new(name: 'CheckIfPhoneNumberIsOptedOutInput')
    CheckIfPhoneNumberIsOptedOutResponse = Shapes::StructureShape.new(name: 'CheckIfPhoneNumberIsOptedOutResponse')
    ConcurrentAccessException = Shapes::StructureShape.new(name: 'ConcurrentAccessException')
    ConfirmSubscriptionInput = Shapes::StructureShape.new(name: 'ConfirmSubscriptionInput')
    ConfirmSubscriptionResponse = Shapes::StructureShape.new(name: 'ConfirmSubscriptionResponse')
    CreateEndpointResponse = Shapes::StructureShape.new(name: 'CreateEndpointResponse')
    CreatePlatformApplicationInput = Shapes::StructureShape.new(name: 'CreatePlatformApplicationInput')
    CreatePlatformApplicationResponse = Shapes::StructureShape.new(name: 'CreatePlatformApplicationResponse')
    CreatePlatformEndpointInput = Shapes::StructureShape.new(name: 'CreatePlatformEndpointInput')
    CreateTopicInput = Shapes::StructureShape.new(name: 'CreateTopicInput')
    CreateTopicResponse = Shapes::StructureShape.new(name: 'CreateTopicResponse')
    DelegatesList = Shapes::ListShape.new(name: 'DelegatesList')
    DeleteEndpointInput = Shapes::StructureShape.new(name: 'DeleteEndpointInput')
    DeletePlatformApplicationInput = Shapes::StructureShape.new(name: 'DeletePlatformApplicationInput')
    DeleteTopicInput = Shapes::StructureShape.new(name: 'DeleteTopicInput')
    Endpoint = Shapes::StructureShape.new(name: 'Endpoint')
    EndpointDisabledException = Shapes::StructureShape.new(name: 'EndpointDisabledException')
    FilterPolicyLimitExceededException = Shapes::StructureShape.new(name: 'FilterPolicyLimitExceededException')
    GetEndpointAttributesInput = Shapes::StructureShape.new(name: 'GetEndpointAttributesInput')
    GetEndpointAttributesResponse = Shapes::StructureShape.new(name: 'GetEndpointAttributesResponse')
    GetPlatformApplicationAttributesInput = Shapes::StructureShape.new(name: 'GetPlatformApplicationAttributesInput')
    GetPlatformApplicationAttributesResponse = Shapes::StructureShape.new(name: 'GetPlatformApplicationAttributesResponse')
    GetSMSAttributesInput = Shapes::StructureShape.new(name: 'GetSMSAttributesInput')
    GetSMSAttributesResponse = Shapes::StructureShape.new(name: 'GetSMSAttributesResponse')
    GetSubscriptionAttributesInput = Shapes::StructureShape.new(name: 'GetSubscriptionAttributesInput')
    GetSubscriptionAttributesResponse = Shapes::StructureShape.new(name: 'GetSubscriptionAttributesResponse')
    GetTopicAttributesInput = Shapes::StructureShape.new(name: 'GetTopicAttributesInput')
    GetTopicAttributesResponse = Shapes::StructureShape.new(name: 'GetTopicAttributesResponse')
    InternalErrorException = Shapes::StructureShape.new(name: 'InternalErrorException')
    InvalidParameterException = Shapes::StructureShape.new(name: 'InvalidParameterException')
    InvalidParameterValueException = Shapes::StructureShape.new(name: 'InvalidParameterValueException')
    InvalidSecurityException = Shapes::StructureShape.new(name: 'InvalidSecurityException')
    KMSAccessDeniedException = Shapes::StructureShape.new(name: 'KMSAccessDeniedException')
    KMSDisabledException = Shapes::StructureShape.new(name: 'KMSDisabledException')
    KMSInvalidStateException = Shapes::StructureShape.new(name: 'KMSInvalidStateException')
    KMSNotFoundException = Shapes::StructureShape.new(name: 'KMSNotFoundException')
    KMSOptInRequired = Shapes::StructureShape.new(name: 'KMSOptInRequired')
    KMSThrottlingException = Shapes::StructureShape.new(name: 'KMSThrottlingException')
    ListEndpointsByPlatformApplicationInput = Shapes::StructureShape.new(name: 'ListEndpointsByPlatformApplicationInput')
    ListEndpointsByPlatformApplicationResponse = Shapes::StructureShape.new(name: 'ListEndpointsByPlatformApplicationResponse')
    ListOfEndpoints = Shapes::ListShape.new(name: 'ListOfEndpoints')
    ListOfPlatformApplications = Shapes::ListShape.new(name: 'ListOfPlatformApplications')
    ListPhoneNumbersOptedOutInput = Shapes::StructureShape.new(name: 'ListPhoneNumbersOptedOutInput')
    ListPhoneNumbersOptedOutResponse = Shapes::StructureShape.new(name: 'ListPhoneNumbersOptedOutResponse')
    ListPlatformApplicationsInput = Shapes::StructureShape.new(name: 'ListPlatformApplicationsInput')
    ListPlatformApplicationsResponse = Shapes::StructureShape.new(name: 'ListPlatformApplicationsResponse')
    ListString = Shapes::ListShape.new(name: 'ListString')
    ListSubscriptionsByTopicInput = Shapes::StructureShape.new(name: 'ListSubscriptionsByTopicInput')
    ListSubscriptionsByTopicResponse = Shapes::StructureShape.new(name: 'ListSubscriptionsByTopicResponse')
    ListSubscriptionsInput = Shapes::StructureShape.new(name: 'ListSubscriptionsInput')
    ListSubscriptionsResponse = Shapes::StructureShape.new(name: 'ListSubscriptionsResponse')
    ListTagsForResourceRequest = Shapes::StructureShape.new(name: 'ListTagsForResourceRequest')
    ListTagsForResourceResponse = Shapes::StructureShape.new(name: 'ListTagsForResourceResponse')
    ListTopicsInput = Shapes::StructureShape.new(name: 'ListTopicsInput')
    ListTopicsResponse = Shapes::StructureShape.new(name: 'ListTopicsResponse')
    MapStringToString = Shapes::MapShape.new(name: 'MapStringToString')
    MessageAttributeMap = Shapes::MapShape.new(name: 'MessageAttributeMap')
    MessageAttributeValue = Shapes::StructureShape.new(name: 'MessageAttributeValue')
    NotFoundException = Shapes::StructureShape.new(name: 'NotFoundException')
    OptInPhoneNumberInput = Shapes::StructureShape.new(name: 'OptInPhoneNumberInput')
    OptInPhoneNumberResponse = Shapes::StructureShape.new(name: 'OptInPhoneNumberResponse')
    PhoneNumber = Shapes::StringShape.new(name: 'PhoneNumber')
    PhoneNumberList = Shapes::ListShape.new(name: 'PhoneNumberList')
    PlatformApplication = Shapes::StructureShape.new(name: 'PlatformApplication')
    PlatformApplicationDisabledException = Shapes::StructureShape.new(name: 'PlatformApplicationDisabledException')
    PublishInput = Shapes::StructureShape.new(name: 'PublishInput')
    PublishResponse = Shapes::StructureShape.new(name: 'PublishResponse')
    RemovePermissionInput = Shapes::StructureShape.new(name: 'RemovePermissionInput')
    ResourceNotFoundException = Shapes::StructureShape.new(name: 'ResourceNotFoundException')
    SetEndpointAttributesInput = Shapes::StructureShape.new(name: 'SetEndpointAttributesInput')
    SetPlatformApplicationAttributesInput = Shapes::StructureShape.new(name: 'SetPlatformApplicationAttributesInput')
    SetSMSAttributesInput = Shapes::StructureShape.new(name: 'SetSMSAttributesInput')
    SetSMSAttributesResponse = Shapes::StructureShape.new(name: 'SetSMSAttributesResponse')
    SetSubscriptionAttributesInput = Shapes::StructureShape.new(name: 'SetSubscriptionAttributesInput')
    SetTopicAttributesInput = Shapes::StructureShape.new(name: 'SetTopicAttributesInput')
    StaleTagException = Shapes::StructureShape.new(name: 'StaleTagException')
    String = Shapes::StringShape.new(name: 'String')
    SubscribeInput = Shapes::StructureShape.new(name: 'SubscribeInput')
    SubscribeResponse = Shapes::StructureShape.new(name: 'SubscribeResponse')
    Subscription = Shapes::StructureShape.new(name: 'Subscription')
    SubscriptionAttributesMap = Shapes::MapShape.new(name: 'SubscriptionAttributesMap')
    SubscriptionLimitExceededException = Shapes::StructureShape.new(name: 'SubscriptionLimitExceededException')
    SubscriptionsList = Shapes::ListShape.new(name: 'SubscriptionsList')
    Tag = Shapes::StructureShape.new(name: 'Tag')
    TagKey = Shapes::StringShape.new(name: 'TagKey')
    TagKeyList = Shapes::ListShape.new(name: 'TagKeyList')
    TagLimitExceededException = Shapes::StructureShape.new(name: 'TagLimitExceededException')
    TagList = Shapes::ListShape.new(name: 'TagList')
    TagPolicyException = Shapes::StructureShape.new(name: 'TagPolicyException')
    TagResourceRequest = Shapes::StructureShape.new(name: 'TagResourceRequest')
    TagResourceResponse = Shapes::StructureShape.new(name: 'TagResourceResponse')
    TagValue = Shapes::StringShape.new(name: 'TagValue')
    ThrottledException = Shapes::StructureShape.new(name: 'ThrottledException')
    Topic = Shapes::StructureShape.new(name: 'Topic')
    TopicAttributesMap = Shapes::MapShape.new(name: 'TopicAttributesMap')
    TopicLimitExceededException = Shapes::StructureShape.new(name: 'TopicLimitExceededException')
    TopicsList = Shapes::ListShape.new(name: 'TopicsList')
    UnsubscribeInput = Shapes::StructureShape.new(name: 'UnsubscribeInput')
    UntagResourceRequest = Shapes::StructureShape.new(name: 'UntagResourceRequest')
    UntagResourceResponse = Shapes::StructureShape.new(name: 'UntagResourceResponse')
    account = Shapes::StringShape.new(name: 'account')
    action = Shapes::StringShape.new(name: 'action')
    attributeName = Shapes::StringShape.new(name: 'attributeName')
    attributeValue = Shapes::StringShape.new(name: 'attributeValue')
    authenticateOnUnsubscribe = Shapes::StringShape.new(name: 'authenticateOnUnsubscribe')
    boolean = Shapes::BooleanShape.new(name: 'boolean')
    delegate = Shapes::StringShape.new(name: 'delegate')
    endpoint = Shapes::StringShape.new(name: 'endpoint')
    label = Shapes::StringShape.new(name: 'label')
    message = Shapes::StringShape.new(name: 'message')
    messageId = Shapes::StringShape.new(name: 'messageId')
    messageStructure = Shapes::StringShape.new(name: 'messageStructure')
    nextToken = Shapes::StringShape.new(name: 'nextToken')
    protocol = Shapes::StringShape.new(name: 'protocol')
    string = Shapes::StringShape.new(name: 'string')
    subject = Shapes::StringShape.new(name: 'subject')
    subscriptionARN = Shapes::StringShape.new(name: 'subscriptionARN')
    token = Shapes::StringShape.new(name: 'token')
    topicARN = Shapes::StringShape.new(name: 'topicARN')
    topicName = Shapes::StringShape.new(name: 'topicName')

    ActionsList.member = Shapes::ShapeRef.new(shape: action)

    AddPermissionInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    AddPermissionInput.add_member(:label, Shapes::ShapeRef.new(shape: label, required: true, location_name: "Label"))
    AddPermissionInput.add_member(:aws_account_id, Shapes::ShapeRef.new(shape: DelegatesList, required: true, location_name: "AWSAccountId"))
    AddPermissionInput.add_member(:action_name, Shapes::ShapeRef.new(shape: ActionsList, required: true, location_name: "ActionName"))
    AddPermissionInput.struct_class = Types::AddPermissionInput

    AuthorizationErrorException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    AuthorizationErrorException.struct_class = Types::AuthorizationErrorException

    CheckIfPhoneNumberIsOptedOutInput.add_member(:phone_number, Shapes::ShapeRef.new(shape: PhoneNumber, required: true, location_name: "phoneNumber"))
    CheckIfPhoneNumberIsOptedOutInput.struct_class = Types::CheckIfPhoneNumberIsOptedOutInput

    CheckIfPhoneNumberIsOptedOutResponse.add_member(:is_opted_out, Shapes::ShapeRef.new(shape: boolean, location_name: "isOptedOut"))
    CheckIfPhoneNumberIsOptedOutResponse.struct_class = Types::CheckIfPhoneNumberIsOptedOutResponse

    ConcurrentAccessException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    ConcurrentAccessException.struct_class = Types::ConcurrentAccessException

    ConfirmSubscriptionInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    ConfirmSubscriptionInput.add_member(:token, Shapes::ShapeRef.new(shape: token, required: true, location_name: "Token"))
    ConfirmSubscriptionInput.add_member(:authenticate_on_unsubscribe, Shapes::ShapeRef.new(shape: authenticateOnUnsubscribe, location_name: "AuthenticateOnUnsubscribe"))
    ConfirmSubscriptionInput.struct_class = Types::ConfirmSubscriptionInput

    ConfirmSubscriptionResponse.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, location_name: "SubscriptionArn"))
    ConfirmSubscriptionResponse.struct_class = Types::ConfirmSubscriptionResponse

    CreateEndpointResponse.add_member(:endpoint_arn, Shapes::ShapeRef.new(shape: String, location_name: "EndpointArn"))
    CreateEndpointResponse.struct_class = Types::CreateEndpointResponse

    CreatePlatformApplicationInput.add_member(:name, Shapes::ShapeRef.new(shape: String, required: true, location_name: "Name"))
    CreatePlatformApplicationInput.add_member(:platform, Shapes::ShapeRef.new(shape: String, required: true, location_name: "Platform"))
    CreatePlatformApplicationInput.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, required: true, location_name: "Attributes"))
    CreatePlatformApplicationInput.struct_class = Types::CreatePlatformApplicationInput

    CreatePlatformApplicationResponse.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, location_name: "PlatformApplicationArn"))
    CreatePlatformApplicationResponse.struct_class = Types::CreatePlatformApplicationResponse

    CreatePlatformEndpointInput.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "PlatformApplicationArn"))
    CreatePlatformEndpointInput.add_member(:token, Shapes::ShapeRef.new(shape: String, required: true, location_name: "Token"))
    CreatePlatformEndpointInput.add_member(:custom_user_data, Shapes::ShapeRef.new(shape: String, location_name: "CustomUserData"))
    CreatePlatformEndpointInput.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "Attributes"))
    CreatePlatformEndpointInput.struct_class = Types::CreatePlatformEndpointInput

    CreateTopicInput.add_member(:name, Shapes::ShapeRef.new(shape: topicName, required: true, location_name: "Name"))
    CreateTopicInput.add_member(:attributes, Shapes::ShapeRef.new(shape: TopicAttributesMap, location_name: "Attributes"))
    CreateTopicInput.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    CreateTopicInput.struct_class = Types::CreateTopicInput

    CreateTopicResponse.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, location_name: "TopicArn"))
    CreateTopicResponse.struct_class = Types::CreateTopicResponse

    DelegatesList.member = Shapes::ShapeRef.new(shape: delegate)

    DeleteEndpointInput.add_member(:endpoint_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "EndpointArn"))
    DeleteEndpointInput.struct_class = Types::DeleteEndpointInput

    DeletePlatformApplicationInput.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "PlatformApplicationArn"))
    DeletePlatformApplicationInput.struct_class = Types::DeletePlatformApplicationInput

    DeleteTopicInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    DeleteTopicInput.struct_class = Types::DeleteTopicInput

    Endpoint.add_member(:endpoint_arn, Shapes::ShapeRef.new(shape: String, location_name: "EndpointArn"))
    Endpoint.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "Attributes"))
    Endpoint.struct_class = Types::Endpoint

    EndpointDisabledException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    EndpointDisabledException.struct_class = Types::EndpointDisabledException

    FilterPolicyLimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    FilterPolicyLimitExceededException.struct_class = Types::FilterPolicyLimitExceededException

    GetEndpointAttributesInput.add_member(:endpoint_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "EndpointArn"))
    GetEndpointAttributesInput.struct_class = Types::GetEndpointAttributesInput

    GetEndpointAttributesResponse.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "Attributes"))
    GetEndpointAttributesResponse.struct_class = Types::GetEndpointAttributesResponse

    GetPlatformApplicationAttributesInput.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "PlatformApplicationArn"))
    GetPlatformApplicationAttributesInput.struct_class = Types::GetPlatformApplicationAttributesInput

    GetPlatformApplicationAttributesResponse.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "Attributes"))
    GetPlatformApplicationAttributesResponse.struct_class = Types::GetPlatformApplicationAttributesResponse

    GetSMSAttributesInput.add_member(:attributes, Shapes::ShapeRef.new(shape: ListString, location_name: "attributes"))
    GetSMSAttributesInput.struct_class = Types::GetSMSAttributesInput

    GetSMSAttributesResponse.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "attributes"))
    GetSMSAttributesResponse.struct_class = Types::GetSMSAttributesResponse

    GetSubscriptionAttributesInput.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, required: true, location_name: "SubscriptionArn"))
    GetSubscriptionAttributesInput.struct_class = Types::GetSubscriptionAttributesInput

    GetSubscriptionAttributesResponse.add_member(:attributes, Shapes::ShapeRef.new(shape: SubscriptionAttributesMap, location_name: "Attributes"))
    GetSubscriptionAttributesResponse.struct_class = Types::GetSubscriptionAttributesResponse

    GetTopicAttributesInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    GetTopicAttributesInput.struct_class = Types::GetTopicAttributesInput

    GetTopicAttributesResponse.add_member(:attributes, Shapes::ShapeRef.new(shape: TopicAttributesMap, location_name: "Attributes"))
    GetTopicAttributesResponse.struct_class = Types::GetTopicAttributesResponse

    InternalErrorException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    InternalErrorException.struct_class = Types::InternalErrorException

    InvalidParameterException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    InvalidParameterException.struct_class = Types::InvalidParameterException

    InvalidParameterValueException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    InvalidParameterValueException.struct_class = Types::InvalidParameterValueException

    InvalidSecurityException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    InvalidSecurityException.struct_class = Types::InvalidSecurityException

    KMSAccessDeniedException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSAccessDeniedException.struct_class = Types::KMSAccessDeniedException

    KMSDisabledException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSDisabledException.struct_class = Types::KMSDisabledException

    KMSInvalidStateException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSInvalidStateException.struct_class = Types::KMSInvalidStateException

    KMSNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSNotFoundException.struct_class = Types::KMSNotFoundException

    KMSOptInRequired.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSOptInRequired.struct_class = Types::KMSOptInRequired

    KMSThrottlingException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    KMSThrottlingException.struct_class = Types::KMSThrottlingException

    ListEndpointsByPlatformApplicationInput.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "PlatformApplicationArn"))
    ListEndpointsByPlatformApplicationInput.add_member(:next_token, Shapes::ShapeRef.new(shape: String, location_name: "NextToken"))
    ListEndpointsByPlatformApplicationInput.struct_class = Types::ListEndpointsByPlatformApplicationInput

    ListEndpointsByPlatformApplicationResponse.add_member(:endpoints, Shapes::ShapeRef.new(shape: ListOfEndpoints, location_name: "Endpoints"))
    ListEndpointsByPlatformApplicationResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: String, location_name: "NextToken"))
    ListEndpointsByPlatformApplicationResponse.struct_class = Types::ListEndpointsByPlatformApplicationResponse

    ListOfEndpoints.member = Shapes::ShapeRef.new(shape: Endpoint)

    ListOfPlatformApplications.member = Shapes::ShapeRef.new(shape: PlatformApplication)

    ListPhoneNumbersOptedOutInput.add_member(:next_token, Shapes::ShapeRef.new(shape: string, location_name: "nextToken"))
    ListPhoneNumbersOptedOutInput.struct_class = Types::ListPhoneNumbersOptedOutInput

    ListPhoneNumbersOptedOutResponse.add_member(:phone_numbers, Shapes::ShapeRef.new(shape: PhoneNumberList, location_name: "phoneNumbers"))
    ListPhoneNumbersOptedOutResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: string, location_name: "nextToken"))
    ListPhoneNumbersOptedOutResponse.struct_class = Types::ListPhoneNumbersOptedOutResponse

    ListPlatformApplicationsInput.add_member(:next_token, Shapes::ShapeRef.new(shape: String, location_name: "NextToken"))
    ListPlatformApplicationsInput.struct_class = Types::ListPlatformApplicationsInput

    ListPlatformApplicationsResponse.add_member(:platform_applications, Shapes::ShapeRef.new(shape: ListOfPlatformApplications, location_name: "PlatformApplications"))
    ListPlatformApplicationsResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: String, location_name: "NextToken"))
    ListPlatformApplicationsResponse.struct_class = Types::ListPlatformApplicationsResponse

    ListString.member = Shapes::ShapeRef.new(shape: String)

    ListSubscriptionsByTopicInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    ListSubscriptionsByTopicInput.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListSubscriptionsByTopicInput.struct_class = Types::ListSubscriptionsByTopicInput

    ListSubscriptionsByTopicResponse.add_member(:subscriptions, Shapes::ShapeRef.new(shape: SubscriptionsList, location_name: "Subscriptions"))
    ListSubscriptionsByTopicResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListSubscriptionsByTopicResponse.struct_class = Types::ListSubscriptionsByTopicResponse

    ListSubscriptionsInput.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListSubscriptionsInput.struct_class = Types::ListSubscriptionsInput

    ListSubscriptionsResponse.add_member(:subscriptions, Shapes::ShapeRef.new(shape: SubscriptionsList, location_name: "Subscriptions"))
    ListSubscriptionsResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListSubscriptionsResponse.struct_class = Types::ListSubscriptionsResponse

    ListTagsForResourceRequest.add_member(:resource_arn, Shapes::ShapeRef.new(shape: AmazonResourceName, required: true, location_name: "ResourceArn"))
    ListTagsForResourceRequest.struct_class = Types::ListTagsForResourceRequest

    ListTagsForResourceResponse.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    ListTagsForResourceResponse.struct_class = Types::ListTagsForResourceResponse

    ListTopicsInput.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListTopicsInput.struct_class = Types::ListTopicsInput

    ListTopicsResponse.add_member(:topics, Shapes::ShapeRef.new(shape: TopicsList, location_name: "Topics"))
    ListTopicsResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: nextToken, location_name: "NextToken"))
    ListTopicsResponse.struct_class = Types::ListTopicsResponse

    MapStringToString.key = Shapes::ShapeRef.new(shape: String)
    MapStringToString.value = Shapes::ShapeRef.new(shape: String)

    MessageAttributeMap.key = Shapes::ShapeRef.new(shape: String, location_name: "Name")
    MessageAttributeMap.value = Shapes::ShapeRef.new(shape: MessageAttributeValue, location_name: "Value")

    MessageAttributeValue.add_member(:data_type, Shapes::ShapeRef.new(shape: String, required: true, location_name: "DataType"))
    MessageAttributeValue.add_member(:string_value, Shapes::ShapeRef.new(shape: String, location_name: "StringValue"))
    MessageAttributeValue.add_member(:binary_value, Shapes::ShapeRef.new(shape: Binary, location_name: "BinaryValue"))
    MessageAttributeValue.struct_class = Types::MessageAttributeValue

    NotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    NotFoundException.struct_class = Types::NotFoundException

    OptInPhoneNumberInput.add_member(:phone_number, Shapes::ShapeRef.new(shape: PhoneNumber, required: true, location_name: "phoneNumber"))
    OptInPhoneNumberInput.struct_class = Types::OptInPhoneNumberInput

    OptInPhoneNumberResponse.struct_class = Types::OptInPhoneNumberResponse

    PhoneNumberList.member = Shapes::ShapeRef.new(shape: PhoneNumber)

    PlatformApplication.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, location_name: "PlatformApplicationArn"))
    PlatformApplication.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, location_name: "Attributes"))
    PlatformApplication.struct_class = Types::PlatformApplication

    PlatformApplicationDisabledException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    PlatformApplicationDisabledException.struct_class = Types::PlatformApplicationDisabledException

    PublishInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, location_name: "TopicArn"))
    PublishInput.add_member(:target_arn, Shapes::ShapeRef.new(shape: String, location_name: "TargetArn"))
    PublishInput.add_member(:phone_number, Shapes::ShapeRef.new(shape: String, location_name: "PhoneNumber"))
    PublishInput.add_member(:message, Shapes::ShapeRef.new(shape: message, required: true, location_name: "Message"))
    PublishInput.add_member(:subject, Shapes::ShapeRef.new(shape: subject, location_name: "Subject"))
    PublishInput.add_member(:message_structure, Shapes::ShapeRef.new(shape: messageStructure, location_name: "MessageStructure"))
    PublishInput.add_member(:message_attributes, Shapes::ShapeRef.new(shape: MessageAttributeMap, location_name: "MessageAttributes"))
    PublishInput.struct_class = Types::PublishInput

    PublishResponse.add_member(:message_id, Shapes::ShapeRef.new(shape: messageId, location_name: "MessageId"))
    PublishResponse.struct_class = Types::PublishResponse

    RemovePermissionInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    RemovePermissionInput.add_member(:label, Shapes::ShapeRef.new(shape: label, required: true, location_name: "Label"))
    RemovePermissionInput.struct_class = Types::RemovePermissionInput

    ResourceNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    ResourceNotFoundException.struct_class = Types::ResourceNotFoundException

    SetEndpointAttributesInput.add_member(:endpoint_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "EndpointArn"))
    SetEndpointAttributesInput.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, required: true, location_name: "Attributes"))
    SetEndpointAttributesInput.struct_class = Types::SetEndpointAttributesInput

    SetPlatformApplicationAttributesInput.add_member(:platform_application_arn, Shapes::ShapeRef.new(shape: String, required: true, location_name: "PlatformApplicationArn"))
    SetPlatformApplicationAttributesInput.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, required: true, location_name: "Attributes"))
    SetPlatformApplicationAttributesInput.struct_class = Types::SetPlatformApplicationAttributesInput

    SetSMSAttributesInput.add_member(:attributes, Shapes::ShapeRef.new(shape: MapStringToString, required: true, location_name: "attributes"))
    SetSMSAttributesInput.struct_class = Types::SetSMSAttributesInput

    SetSMSAttributesResponse.struct_class = Types::SetSMSAttributesResponse

    SetSubscriptionAttributesInput.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, required: true, location_name: "SubscriptionArn"))
    SetSubscriptionAttributesInput.add_member(:attribute_name, Shapes::ShapeRef.new(shape: attributeName, required: true, location_name: "AttributeName"))
    SetSubscriptionAttributesInput.add_member(:attribute_value, Shapes::ShapeRef.new(shape: attributeValue, location_name: "AttributeValue"))
    SetSubscriptionAttributesInput.struct_class = Types::SetSubscriptionAttributesInput

    SetTopicAttributesInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    SetTopicAttributesInput.add_member(:attribute_name, Shapes::ShapeRef.new(shape: attributeName, required: true, location_name: "AttributeName"))
    SetTopicAttributesInput.add_member(:attribute_value, Shapes::ShapeRef.new(shape: attributeValue, location_name: "AttributeValue"))
    SetTopicAttributesInput.struct_class = Types::SetTopicAttributesInput

    StaleTagException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    StaleTagException.struct_class = Types::StaleTagException

    SubscribeInput.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, required: true, location_name: "TopicArn"))
    SubscribeInput.add_member(:protocol, Shapes::ShapeRef.new(shape: protocol, required: true, location_name: "Protocol"))
    SubscribeInput.add_member(:endpoint, Shapes::ShapeRef.new(shape: endpoint, location_name: "Endpoint"))
    SubscribeInput.add_member(:attributes, Shapes::ShapeRef.new(shape: SubscriptionAttributesMap, location_name: "Attributes"))
    SubscribeInput.add_member(:return_subscription_arn, Shapes::ShapeRef.new(shape: boolean, location_name: "ReturnSubscriptionArn"))
    SubscribeInput.struct_class = Types::SubscribeInput

    SubscribeResponse.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, location_name: "SubscriptionArn"))
    SubscribeResponse.struct_class = Types::SubscribeResponse

    Subscription.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, location_name: "SubscriptionArn"))
    Subscription.add_member(:owner, Shapes::ShapeRef.new(shape: account, location_name: "Owner"))
    Subscription.add_member(:protocol, Shapes::ShapeRef.new(shape: protocol, location_name: "Protocol"))
    Subscription.add_member(:endpoint, Shapes::ShapeRef.new(shape: endpoint, location_name: "Endpoint"))
    Subscription.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, location_name: "TopicArn"))
    Subscription.struct_class = Types::Subscription

    SubscriptionAttributesMap.key = Shapes::ShapeRef.new(shape: attributeName)
    SubscriptionAttributesMap.value = Shapes::ShapeRef.new(shape: attributeValue)

    SubscriptionLimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    SubscriptionLimitExceededException.struct_class = Types::SubscriptionLimitExceededException

    SubscriptionsList.member = Shapes::ShapeRef.new(shape: Subscription)

    Tag.add_member(:key, Shapes::ShapeRef.new(shape: TagKey, required: true, location_name: "Key"))
    Tag.add_member(:value, Shapes::ShapeRef.new(shape: TagValue, required: true, location_name: "Value"))
    Tag.struct_class = Types::Tag

    TagKeyList.member = Shapes::ShapeRef.new(shape: TagKey)

    TagLimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    TagLimitExceededException.struct_class = Types::TagLimitExceededException

    TagList.member = Shapes::ShapeRef.new(shape: Tag)

    TagPolicyException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    TagPolicyException.struct_class = Types::TagPolicyException

    TagResourceRequest.add_member(:resource_arn, Shapes::ShapeRef.new(shape: AmazonResourceName, required: true, location_name: "ResourceArn"))
    TagResourceRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, required: true, location_name: "Tags"))
    TagResourceRequest.struct_class = Types::TagResourceRequest

    TagResourceResponse.struct_class = Types::TagResourceResponse

    ThrottledException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    ThrottledException.struct_class = Types::ThrottledException

    Topic.add_member(:topic_arn, Shapes::ShapeRef.new(shape: topicARN, location_name: "TopicArn"))
    Topic.struct_class = Types::Topic

    TopicAttributesMap.key = Shapes::ShapeRef.new(shape: attributeName)
    TopicAttributesMap.value = Shapes::ShapeRef.new(shape: attributeValue)

    TopicLimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: string, location_name: "message"))
    TopicLimitExceededException.struct_class = Types::TopicLimitExceededException

    TopicsList.member = Shapes::ShapeRef.new(shape: Topic)

    UnsubscribeInput.add_member(:subscription_arn, Shapes::ShapeRef.new(shape: subscriptionARN, required: true, location_name: "SubscriptionArn"))
    UnsubscribeInput.struct_class = Types::UnsubscribeInput

    UntagResourceRequest.add_member(:resource_arn, Shapes::ShapeRef.new(shape: AmazonResourceName, required: true, location_name: "ResourceArn"))
    UntagResourceRequest.add_member(:tag_keys, Shapes::ShapeRef.new(shape: TagKeyList, required: true, location_name: "TagKeys"))
    UntagResourceRequest.struct_class = Types::UntagResourceRequest

    UntagResourceResponse.struct_class = Types::UntagResourceResponse


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2010-03-31"

      api.metadata = {
        "apiVersion" => "2010-03-31",
        "endpointPrefix" => "sns",
        "protocol" => "query",
        "serviceAbbreviation" => "Amazon SNS",
        "serviceFullName" => "Amazon Simple Notification Service",
        "serviceId" => "SNS",
        "signatureVersion" => "v4",
        "uid" => "sns-2010-03-31",
        "xmlNamespace" => "http://sns.amazonaws.com/doc/2010-03-31/",
      }

      api.add_operation(:add_permission, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AddPermission"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: AddPermissionInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:check_if_phone_number_is_opted_out, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CheckIfPhoneNumberIsOptedOut"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CheckIfPhoneNumberIsOptedOutInput)
        o.output = Shapes::ShapeRef.new(shape: CheckIfPhoneNumberIsOptedOutResponse)
        o.errors << Shapes::ShapeRef.new(shape: ThrottledException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
      end)

      api.add_operation(:confirm_subscription, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ConfirmSubscription"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ConfirmSubscriptionInput)
        o.output = Shapes::ShapeRef.new(shape: ConfirmSubscriptionResponse)
        o.errors << Shapes::ShapeRef.new(shape: SubscriptionLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: FilterPolicyLimitExceededException)
      end)

      api.add_operation(:create_platform_application, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreatePlatformApplication"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreatePlatformApplicationInput)
        o.output = Shapes::ShapeRef.new(shape: CreatePlatformApplicationResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:create_platform_endpoint, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreatePlatformEndpoint"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreatePlatformEndpointInput)
        o.output = Shapes::ShapeRef.new(shape: CreateEndpointResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:create_topic, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateTopic"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateTopicInput)
        o.output = Shapes::ShapeRef.new(shape: CreateTopicResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: TopicLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
        o.errors << Shapes::ShapeRef.new(shape: TagLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: StaleTagException)
        o.errors << Shapes::ShapeRef.new(shape: TagPolicyException)
        o.errors << Shapes::ShapeRef.new(shape: ConcurrentAccessException)
      end)

      api.add_operation(:delete_endpoint, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteEndpoint"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteEndpointInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:delete_platform_application, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeletePlatformApplication"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeletePlatformApplicationInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:delete_topic, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteTopic"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteTopicInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: StaleTagException)
        o.errors << Shapes::ShapeRef.new(shape: TagPolicyException)
        o.errors << Shapes::ShapeRef.new(shape: ConcurrentAccessException)
      end)

      api.add_operation(:get_endpoint_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetEndpointAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetEndpointAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: GetEndpointAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:get_platform_application_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetPlatformApplicationAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetPlatformApplicationAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: GetPlatformApplicationAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:get_sms_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetSMSAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetSMSAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: GetSMSAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: ThrottledException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
      end)

      api.add_operation(:get_subscription_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetSubscriptionAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetSubscriptionAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: GetSubscriptionAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:get_topic_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetTopicAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetTopicAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: GetTopicAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
      end)

      api.add_operation(:list_endpoints_by_platform_application, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListEndpointsByPlatformApplication"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListEndpointsByPlatformApplicationInput)
        o.output = Shapes::ShapeRef.new(shape: ListEndpointsByPlatformApplicationResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o[:pager] = Aws::Pager.new(
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:list_phone_numbers_opted_out, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListPhoneNumbersOptedOut"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListPhoneNumbersOptedOutInput)
        o.output = Shapes::ShapeRef.new(shape: ListPhoneNumbersOptedOutResponse)
        o.errors << Shapes::ShapeRef.new(shape: ThrottledException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
      end)

      api.add_operation(:list_platform_applications, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListPlatformApplications"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListPlatformApplicationsInput)
        o.output = Shapes::ShapeRef.new(shape: ListPlatformApplicationsResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o[:pager] = Aws::Pager.new(
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:list_subscriptions, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListSubscriptions"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListSubscriptionsInput)
        o.output = Shapes::ShapeRef.new(shape: ListSubscriptionsResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o[:pager] = Aws::Pager.new(
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:list_subscriptions_by_topic, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListSubscriptionsByTopic"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListSubscriptionsByTopicInput)
        o.output = Shapes::ShapeRef.new(shape: ListSubscriptionsByTopicResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o[:pager] = Aws::Pager.new(
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:list_tags_for_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListTagsForResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListTagsForResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: ListTagsForResourceResponse)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: TagPolicyException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: ConcurrentAccessException)
      end)

      api.add_operation(:list_topics, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListTopics"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListTopicsInput)
        o.output = Shapes::ShapeRef.new(shape: ListTopicsResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o[:pager] = Aws::Pager.new(
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:opt_in_phone_number, Seahorse::Model::Operation.new.tap do |o|
        o.name = "OptInPhoneNumber"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: OptInPhoneNumberInput)
        o.output = Shapes::ShapeRef.new(shape: OptInPhoneNumberResponse)
        o.errors << Shapes::ShapeRef.new(shape: ThrottledException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
      end)

      api.add_operation(:publish, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Publish"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: PublishInput)
        o.output = Shapes::ShapeRef.new(shape: PublishResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterValueException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: EndpointDisabledException)
        o.errors << Shapes::ShapeRef.new(shape: PlatformApplicationDisabledException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: KMSDisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSOptInRequired)
        o.errors << Shapes::ShapeRef.new(shape: KMSThrottlingException)
        o.errors << Shapes::ShapeRef.new(shape: KMSAccessDeniedException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
      end)

      api.add_operation(:remove_permission, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RemovePermission"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: RemovePermissionInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:set_endpoint_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SetEndpointAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SetEndpointAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:set_platform_application_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SetPlatformApplicationAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SetPlatformApplicationAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
      end)

      api.add_operation(:set_sms_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SetSMSAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SetSMSAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: SetSMSAttributesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: ThrottledException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:set_subscription_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SetSubscriptionAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SetSubscriptionAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: FilterPolicyLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
      end)

      api.add_operation(:set_topic_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SetTopicAttributes"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SetTopicAttributesInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
      end)

      api.add_operation(:subscribe, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Subscribe"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SubscribeInput)
        o.output = Shapes::ShapeRef.new(shape: SubscribeResponse)
        o.errors << Shapes::ShapeRef.new(shape: SubscriptionLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: FilterPolicyLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
      end)

      api.add_operation(:tag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "TagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: TagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: TagResourceResponse)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: TagLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: StaleTagException)
        o.errors << Shapes::ShapeRef.new(shape: TagPolicyException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: ConcurrentAccessException)
      end)

      api.add_operation(:unsubscribe, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Unsubscribe"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UnsubscribeInput)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: InternalErrorException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidSecurityException)
      end)

      api.add_operation(:untag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UntagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UntagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: UntagResourceResponse)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: TagLimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: StaleTagException)
        o.errors << Shapes::ShapeRef.new(shape: TagPolicyException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidParameterException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: ConcurrentAccessException)
      end)
    end

  end
end
