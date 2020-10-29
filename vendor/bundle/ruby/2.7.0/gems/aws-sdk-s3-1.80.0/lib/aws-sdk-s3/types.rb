# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  module Types

    # Specifies the days since the initiation of an incomplete multipart
    # upload that Amazon S3 will wait before permanently removing all parts
    # of the upload. For more information, see [ Aborting Incomplete
    # Multipart Uploads Using a Bucket Lifecycle Policy][1] in the *Amazon
    # Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #
    # @note When making an API call, you may pass AbortIncompleteMultipartUpload
    #   data as a hash:
    #
    #       {
    #         days_after_initiation: 1,
    #       }
    #
    # @!attribute [rw] days_after_initiation
    #   Specifies the number of days after which Amazon S3 aborts an
    #   incomplete multipart upload.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortIncompleteMultipartUpload AWS API Documentation
    #
    class AbortIncompleteMultipartUpload < Struct.new(
      :days_after_initiation)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortMultipartUploadOutput AWS API Documentation
    #
    class AbortMultipartUploadOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass AbortMultipartUploadRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         upload_id: "MultipartUploadId", # required
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name to which the upload was taking place.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key of the object for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   Upload ID that identifies the multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortMultipartUploadRequest AWS API Documentation
    #
    class AbortMultipartUploadRequest < Struct.new(
      :bucket,
      :key,
      :upload_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Configures the transfer acceleration state for an Amazon S3 bucket.
    # For more information, see [Amazon S3 Transfer Acceleration][1] in the
    # *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    #
    # @note When making an API call, you may pass AccelerateConfiguration
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # accepts Enabled, Suspended
    #       }
    #
    # @!attribute [rw] status
    #   Specifies the transfer acceleration status of the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccelerateConfiguration AWS API Documentation
    #
    class AccelerateConfiguration < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the elements that set the ACL permissions for an object per
    # grantee.
    #
    # @note When making an API call, you may pass AccessControlPolicy
    #   data as a hash:
    #
    #       {
    #         grants: [
    #           {
    #             grantee: {
    #               display_name: "DisplayName",
    #               email_address: "EmailAddress",
    #               id: "ID",
    #               type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #               uri: "URI",
    #             },
    #             permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #           },
    #         ],
    #         owner: {
    #           display_name: "DisplayName",
    #           id: "ID",
    #         },
    #       }
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] owner
    #   Container for the bucket owner's display name and ID.
    #   @return [Types::Owner]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccessControlPolicy AWS API Documentation
    #
    class AccessControlPolicy < Struct.new(
      :grants,
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for information about access control for replicas.
    #
    # @note When making an API call, you may pass AccessControlTranslation
    #   data as a hash:
    #
    #       {
    #         owner: "Destination", # required, accepts Destination
    #       }
    #
    # @!attribute [rw] owner
    #   Specifies the replica ownership. For default and valid values, see
    #   [PUT bucket replication][1] in the *Amazon Simple Storage Service
    #   API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTreplication.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AccessControlTranslation AWS API Documentation
    #
    class AccessControlTranslation < Struct.new(
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # A conjunction (logical AND) of predicates, which is used in evaluating
    # a metrics filter. The operator must have at least two predicates in
    # any combination, and an object must match all of the predicates for
    # the filter to apply.
    #
    # @note When making an API call, you may pass AnalyticsAndOperator
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tags: [
    #           {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] prefix
    #   The prefix to use when evaluating an AND predicate: The prefix that
    #   an object must have to be included in the metrics results.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   The list of tags to use when evaluating an AND predicate.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsAndOperator AWS API Documentation
    #
    class AnalyticsAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the configuration and any analyses for the analytics filter
    # of an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass AnalyticsConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "AnalyticsId", # required
    #         filter: {
    #           prefix: "Prefix",
    #           tag: {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #           and: {
    #             prefix: "Prefix",
    #             tags: [
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #         },
    #         storage_class_analysis: { # required
    #           data_export: {
    #             output_schema_version: "V_1", # required, accepts V_1
    #             destination: { # required
    #               s3_bucket_destination: { # required
    #                 format: "CSV", # required, accepts CSV
    #                 bucket_account_id: "AccountId",
    #                 bucket: "BucketName", # required
    #                 prefix: "Prefix",
    #               },
    #             },
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   The filter used to describe a set of objects for analyses. A filter
    #   must have exactly one prefix, one tag, or one conjunction
    #   (AnalyticsAndOperator). If no filter is provided, all objects will
    #   be considered in any analysis.
    #   @return [Types::AnalyticsFilter]
    #
    # @!attribute [rw] storage_class_analysis
    #   Contains data related to access patterns to be collected and made
    #   available to analyze the tradeoffs between different storage
    #   classes.
    #   @return [Types::StorageClassAnalysis]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsConfiguration AWS API Documentation
    #
    class AnalyticsConfiguration < Struct.new(
      :id,
      :filter,
      :storage_class_analysis)
      SENSITIVE = []
      include Aws::Structure
    end

    # Where to publish the analytics results.
    #
    # @note When making an API call, you may pass AnalyticsExportDestination
    #   data as a hash:
    #
    #       {
    #         s3_bucket_destination: { # required
    #           format: "CSV", # required, accepts CSV
    #           bucket_account_id: "AccountId",
    #           bucket: "BucketName", # required
    #           prefix: "Prefix",
    #         },
    #       }
    #
    # @!attribute [rw] s3_bucket_destination
    #   A destination signifying output to an S3 bucket.
    #   @return [Types::AnalyticsS3BucketDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsExportDestination AWS API Documentation
    #
    class AnalyticsExportDestination < Struct.new(
      :s3_bucket_destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # The filter used to describe a set of objects for analyses. A filter
    # must have exactly one prefix, one tag, or one conjunction
    # (AnalyticsAndOperator). If no filter is provided, all objects will be
    # considered in any analysis.
    #
    # @note When making an API call, you may pass AnalyticsFilter
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       }
    #
    # @!attribute [rw] prefix
    #   The prefix to use when evaluating an analytics filter.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   The tag to use when evaluating an analytics filter.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A conjunction (logical AND) of predicates, which is used in
    #   evaluating an analytics filter. The operator must have at least two
    #   predicates.
    #   @return [Types::AnalyticsAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsFilter AWS API Documentation
    #
    class AnalyticsFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains information about where to publish the analytics results.
    #
    # @note When making an API call, you may pass AnalyticsS3BucketDestination
    #   data as a hash:
    #
    #       {
    #         format: "CSV", # required, accepts CSV
    #         bucket_account_id: "AccountId",
    #         bucket: "BucketName", # required
    #         prefix: "Prefix",
    #       }
    #
    # @!attribute [rw] format
    #   Specifies the file format used when exporting data to Amazon S3.
    #   @return [String]
    #
    # @!attribute [rw] bucket_account_id
    #   The account ID that owns the destination S3 bucket. If no account ID
    #   is provided, the owner is not validated before exporting data.
    #
    #   <note markdown="1"> Although this value is optional, we strongly recommend that you set
    #   it to help prevent problems if the destination bucket ownership
    #   changes.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket to which data is
    #   exported.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix to use when exporting data. The prefix is prepended to
    #   all results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AnalyticsS3BucketDestination AWS API Documentation
    #
    class AnalyticsS3BucketDestination < Struct.new(
      :format,
      :bucket_account_id,
      :bucket,
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # In terms of implementation, a Bucket is a resource. An Amazon S3
    # bucket name is globally unique, and the namespace is shared by all AWS
    # accounts.
    #
    # @!attribute [rw] name
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] creation_date
    #   Date the bucket was created.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Bucket AWS API Documentation
    #
    class Bucket < Struct.new(
      :name,
      :creation_date)
      SENSITIVE = []
      include Aws::Structure
    end

    # The requested bucket name is not available. The bucket namespace is
    # shared by all users of the system. Please select a different name and
    # try again.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketAlreadyExists AWS API Documentation
    #
    class BucketAlreadyExists < Aws::EmptyStructure; end

    # The bucket you tried to create already exists, and you own it. Amazon
    # S3 returns this error in all AWS Regions except in the North Virginia
    # Region. For legacy compatibility, if you re-create an existing bucket
    # that you already own in the North Virginia Region, Amazon S3 returns
    # 200 OK and resets the bucket access control lists (ACLs).
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketAlreadyOwnedByYou AWS API Documentation
    #
    class BucketAlreadyOwnedByYou < Aws::EmptyStructure; end

    # Specifies the lifecycle configuration for objects in an Amazon S3
    # bucket. For more information, see [Object Lifecycle Management][1] in
    # the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    #
    # @note When making an API call, you may pass BucketLifecycleConfiguration
    #   data as a hash:
    #
    #       {
    #         rules: [ # required
    #           {
    #             expiration: {
    #               date: Time.now,
    #               days: 1,
    #               expired_object_delete_marker: false,
    #             },
    #             id: "ID",
    #             prefix: "Prefix",
    #             filter: {
    #               prefix: "Prefix",
    #               tag: {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #               and: {
    #                 prefix: "Prefix",
    #                 tags: [
    #                   {
    #                     key: "ObjectKey", # required
    #                     value: "Value", # required
    #                   },
    #                 ],
    #               },
    #             },
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #             transitions: [
    #               {
    #                 date: Time.now,
    #                 days: 1,
    #                 storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #               },
    #             ],
    #             noncurrent_version_transitions: [
    #               {
    #                 noncurrent_days: 1,
    #                 storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #               },
    #             ],
    #             noncurrent_version_expiration: {
    #               noncurrent_days: 1,
    #             },
    #             abort_incomplete_multipart_upload: {
    #               days_after_initiation: 1,
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] rules
    #   A lifecycle rule for individual objects in an Amazon S3 bucket.
    #   @return [Array<Types::LifecycleRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketLifecycleConfiguration AWS API Documentation
    #
    class BucketLifecycleConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for logging status information.
    #
    # @note When making an API call, you may pass BucketLoggingStatus
    #   data as a hash:
    #
    #       {
    #         logging_enabled: {
    #           target_bucket: "TargetBucket", # required
    #           target_grants: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, READ, WRITE
    #             },
    #           ],
    #           target_prefix: "TargetPrefix", # required
    #         },
    #       }
    #
    # @!attribute [rw] logging_enabled
    #   Describes where logs are stored and the prefix that Amazon S3
    #   assigns to all log object keys for a bucket. For more information,
    #   see [PUT Bucket logging][1] in the *Amazon Simple Storage Service
    #   API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #   @return [Types::LoggingEnabled]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/BucketLoggingStatus AWS API Documentation
    #
    class BucketLoggingStatus < Struct.new(
      :logging_enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the cross-origin access configuration for objects in an
    # Amazon S3 bucket. For more information, see [Enabling Cross-Origin
    # Resource Sharing][1] in the *Amazon Simple Storage Service Developer
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    #
    # @note When making an API call, you may pass CORSConfiguration
    #   data as a hash:
    #
    #       {
    #         cors_rules: [ # required
    #           {
    #             allowed_headers: ["AllowedHeader"],
    #             allowed_methods: ["AllowedMethod"], # required
    #             allowed_origins: ["AllowedOrigin"], # required
    #             expose_headers: ["ExposeHeader"],
    #             max_age_seconds: 1,
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] cors_rules
    #   A set of origins and methods (cross-origin access that you want to
    #   allow). You can add up to 100 rules to the configuration.
    #   @return [Array<Types::CORSRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CORSConfiguration AWS API Documentation
    #
    class CORSConfiguration < Struct.new(
      :cors_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a cross-origin access rule for an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass CORSRule
    #   data as a hash:
    #
    #       {
    #         allowed_headers: ["AllowedHeader"],
    #         allowed_methods: ["AllowedMethod"], # required
    #         allowed_origins: ["AllowedOrigin"], # required
    #         expose_headers: ["ExposeHeader"],
    #         max_age_seconds: 1,
    #       }
    #
    # @!attribute [rw] allowed_headers
    #   Headers that are specified in the `Access-Control-Request-Headers`
    #   header. These headers are allowed in a preflight OPTIONS request. In
    #   response to any preflight OPTIONS request, Amazon S3 returns any
    #   requested headers that are allowed.
    #   @return [Array<String>]
    #
    # @!attribute [rw] allowed_methods
    #   An HTTP method that you allow the origin to execute. Valid values
    #   are `GET`, `PUT`, `HEAD`, `POST`, and `DELETE`.
    #   @return [Array<String>]
    #
    # @!attribute [rw] allowed_origins
    #   One or more origins you want customers to be able to access the
    #   bucket from.
    #   @return [Array<String>]
    #
    # @!attribute [rw] expose_headers
    #   One or more headers in the response that you want customers to be
    #   able to access from their applications (for example, from a
    #   JavaScript `XMLHttpRequest` object).
    #   @return [Array<String>]
    #
    # @!attribute [rw] max_age_seconds
    #   The time in seconds that your browser is to cache the preflight
    #   response for the specified resource.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CORSRule AWS API Documentation
    #
    class CORSRule < Struct.new(
      :allowed_headers,
      :allowed_methods,
      :allowed_origins,
      :expose_headers,
      :max_age_seconds)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how an uncompressed comma-separated values (CSV)-formatted
    # input object is formatted.
    #
    # @note When making an API call, you may pass CSVInput
    #   data as a hash:
    #
    #       {
    #         file_header_info: "USE", # accepts USE, IGNORE, NONE
    #         comments: "Comments",
    #         quote_escape_character: "QuoteEscapeCharacter",
    #         record_delimiter: "RecordDelimiter",
    #         field_delimiter: "FieldDelimiter",
    #         quote_character: "QuoteCharacter",
    #         allow_quoted_record_delimiter: false,
    #       }
    #
    # @!attribute [rw] file_header_info
    #   Describes the first line of input. Valid values are:
    #
    #   * `NONE`\: First line is not a header.
    #
    #   * `IGNORE`\: First line is a header, but you can't use the header
    #     values to indicate the column in an expression. You can use column
    #     position (such as \_1, \_2, …) to indicate the column (`SELECT
    #     s._1 FROM OBJECT s`).
    #
    #   * `Use`\: First line is a header, and you can use the header value
    #     to identify a column in an expression (`SELECT "name" FROM
    #     OBJECT`).
    #   @return [String]
    #
    # @!attribute [rw] comments
    #   A single character used to indicate that a row should be ignored
    #   when the character is present at the start of that row. You can
    #   specify any character to indicate a comment line.
    #   @return [String]
    #
    # @!attribute [rw] quote_escape_character
    #   A single character used for escaping the quotation mark character
    #   inside an already escaped value. For example, the value """ a , b
    #   """ is parsed as " a , b ".
    #   @return [String]
    #
    # @!attribute [rw] record_delimiter
    #   A single character used to separate individual records in the input.
    #   Instead of the default value, you can specify an arbitrary
    #   delimiter.
    #   @return [String]
    #
    # @!attribute [rw] field_delimiter
    #   A single character used to separate individual fields in a record.
    #   You can specify an arbitrary delimiter.
    #   @return [String]
    #
    # @!attribute [rw] quote_character
    #   A single character used for escaping when the field delimiter is
    #   part of the value. For example, if the value is `a, b`, Amazon S3
    #   wraps this field value in quotation marks, as follows: `" a , b "`.
    #
    #   Type: String
    #
    #   Default: `"`
    #
    #   Ancestors: `CSV`
    #   @return [String]
    #
    # @!attribute [rw] allow_quoted_record_delimiter
    #   Specifies that CSV field values may contain quoted record delimiters
    #   and such records should be allowed. Default value is FALSE. Setting
    #   this value to TRUE may lower performance.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CSVInput AWS API Documentation
    #
    class CSVInput < Struct.new(
      :file_header_info,
      :comments,
      :quote_escape_character,
      :record_delimiter,
      :field_delimiter,
      :quote_character,
      :allow_quoted_record_delimiter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how uncompressed comma-separated values (CSV)-formatted
    # results are formatted.
    #
    # @note When making an API call, you may pass CSVOutput
    #   data as a hash:
    #
    #       {
    #         quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #         quote_escape_character: "QuoteEscapeCharacter",
    #         record_delimiter: "RecordDelimiter",
    #         field_delimiter: "FieldDelimiter",
    #         quote_character: "QuoteCharacter",
    #       }
    #
    # @!attribute [rw] quote_fields
    #   Indicates whether to use quotation marks around output fields.
    #
    #   * `ALWAYS`\: Always use quotation marks for output fields.
    #
    #   * `ASNEEDED`\: Use quotation marks for output fields when needed.
    #   @return [String]
    #
    # @!attribute [rw] quote_escape_character
    #   The single character used for escaping the quote character inside an
    #   already escaped value.
    #   @return [String]
    #
    # @!attribute [rw] record_delimiter
    #   A single character used to separate individual records in the
    #   output. Instead of the default value, you can specify an arbitrary
    #   delimiter.
    #   @return [String]
    #
    # @!attribute [rw] field_delimiter
    #   The value used to separate individual fields in a record. You can
    #   specify an arbitrary delimiter.
    #   @return [String]
    #
    # @!attribute [rw] quote_character
    #   A single character used for escaping when the field delimiter is
    #   part of the value. For example, if the value is `a, b`, Amazon S3
    #   wraps this field value in quotation marks, as follows: `" a , b "`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CSVOutput AWS API Documentation
    #
    class CSVOutput < Struct.new(
      :quote_fields,
      :quote_escape_character,
      :record_delimiter,
      :field_delimiter,
      :quote_character)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for specifying the AWS Lambda notification configuration.
    #
    # @note When making an API call, you may pass CloudFunctionConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         cloud_function: "CloudFunction",
    #         invocation_role: "CloudFunctionInvocationRole",
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] event
    #   The bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   Bucket events for which to send notifications.
    #   @return [Array<String>]
    #
    # @!attribute [rw] cloud_function
    #   Lambda cloud function ARN that Amazon S3 can invoke when it detects
    #   events of the specified type.
    #   @return [String]
    #
    # @!attribute [rw] invocation_role
    #   The role supporting the invocation of the Lambda function
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CloudFunctionConfiguration AWS API Documentation
    #
    class CloudFunctionConfiguration < Struct.new(
      :id,
      :event,
      :events,
      :cloud_function,
      :invocation_role)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all (if there are any) keys between Prefix and the next
    # occurrence of the string specified by a delimiter. CommonPrefixes
    # lists keys that act like subdirectories in the directory specified by
    # Prefix. For example, if the prefix is notes/ and the delimiter is a
    # slash (/) as in notes/summer/july, the common prefix is notes/summer/.
    #
    # @!attribute [rw] prefix
    #   Container for the specified common prefix.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CommonPrefix AWS API Documentation
    #
    class CommonPrefix < Struct.new(
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location
    #   The URI that identifies the newly created object.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket that contains the newly created object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key of the newly created object.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured, this will contain the
    #   expiration date (expiry-date) and rule ID (rule-id). The value of
    #   rule-id is URL encoded.
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag that identifies the newly created object's data. Objects
    #   with different object data will have different entity tags. The
    #   entity tag is an opaque string. The entity tag may or may not be an
    #   MD5 digest of the object data. If the entity tag is not an MD5
    #   digest of the object data, it will contain one or more
    #   nonhexadecimal characters and/or will consist of less than 32 or
    #   more than 32 hexadecimal digits.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   If you specified server-side encryption either with an Amazon
    #   S3-managed encryption key or an AWS KMS customer master key (CMK) in
    #   your initiate multipart upload request, the response includes this
    #   header. It confirms the encryption algorithm that Amazon S3 used to
    #   encrypt the object.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of the newly created object, in case the bucket has
    #   versioning turned on.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompleteMultipartUploadOutput AWS API Documentation
    #
    class CompleteMultipartUploadOutput < Struct.new(
      :location,
      :bucket,
      :key,
      :expiration,
      :etag,
      :server_side_encryption,
      :version_id,
      :ssekms_key_id,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @note When making an API call, you may pass CompleteMultipartUploadRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         multipart_upload: {
    #           parts: [
    #             {
    #               etag: "ETag",
    #               part_number: 1,
    #             },
    #           ],
    #         },
    #         upload_id: "MultipartUploadId", # required
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] multipart_upload
    #   The container for the multipart upload request information.
    #   @return [Types::CompletedMultipartUpload]
    #
    # @!attribute [rw] upload_id
    #   ID for the initiated multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompleteMultipartUploadRequest AWS API Documentation
    #
    class CompleteMultipartUploadRequest < Struct.new(
      :bucket,
      :key,
      :multipart_upload,
      :upload_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container for the completed multipart upload details.
    #
    # @note When making an API call, you may pass CompletedMultipartUpload
    #   data as a hash:
    #
    #       {
    #         parts: [
    #           {
    #             etag: "ETag",
    #             part_number: 1,
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] parts
    #   Array of CompletedPart data types.
    #   @return [Array<Types::CompletedPart>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompletedMultipartUpload AWS API Documentation
    #
    class CompletedMultipartUpload < Struct.new(
      :parts)
      SENSITIVE = []
      include Aws::Structure
    end

    # Details of the parts that were uploaded.
    #
    # @note When making an API call, you may pass CompletedPart
    #   data as a hash:
    #
    #       {
    #         etag: "ETag",
    #         part_number: 1,
    #       }
    #
    # @!attribute [rw] etag
    #   Entity tag returned when the part was uploaded.
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number that identifies the part. This is a positive integer
    #   between 1 and 10,000.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompletedPart AWS API Documentation
    #
    class CompletedPart < Struct.new(
      :etag,
      :part_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for describing a condition that must be met for the
    # specified redirect to apply. For example, 1. If request is for pages
    # in the `/docs` folder, redirect to the `/documents` folder. 2. If
    # request results in HTTP error 4xx, redirect request to another host
    # where you might process the error.
    #
    # @note When making an API call, you may pass Condition
    #   data as a hash:
    #
    #       {
    #         http_error_code_returned_equals: "HttpErrorCodeReturnedEquals",
    #         key_prefix_equals: "KeyPrefixEquals",
    #       }
    #
    # @!attribute [rw] http_error_code_returned_equals
    #   The HTTP error code when the redirect is applied. In the event of an
    #   error, if the error code equals this value, then the specified
    #   redirect is applied. Required when parent element `Condition` is
    #   specified and sibling `KeyPrefixEquals` is not specified. If both
    #   are specified, then both must be true for the redirect to be
    #   applied.
    #   @return [String]
    #
    # @!attribute [rw] key_prefix_equals
    #   The object key name prefix when the redirect is applied. For
    #   example, to redirect requests for `ExamplePage.html`, the key prefix
    #   will be `ExamplePage.html`. To redirect request for all pages with
    #   the prefix `docs/`, the key prefix will be `/docs`, which identifies
    #   all objects in the `docs/` folder. Required when the parent element
    #   `Condition` is specified and sibling `HttpErrorCodeReturnedEquals`
    #   is not specified. If both conditions are specified, both must be
    #   true for the redirect to be applied.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Condition AWS API Documentation
    #
    class Condition < Struct.new(
      :http_error_code_returned_equals,
      :key_prefix_equals)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ContinuationEvent AWS API Documentation
    #
    class ContinuationEvent < Struct.new(
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] copy_object_result
    #   Container for all response elements.
    #   @return [Types::CopyObjectResult]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured, the response includes this
    #   header.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_version_id
    #   Version of the copied object in the destination bucket.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of the newly created copy.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, specifies the AWS KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded
    #   UTF-8 string holding JSON with the encryption context key-value
    #   pairs.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectOutput AWS API Documentation
    #
    class CopyObjectOutput < Struct.new(
      :copy_object_result,
      :expiration,
      :copy_source_version_id,
      :version_id,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :request_charged)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @note When making an API call, you may pass CopyObjectRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #         bucket: "BucketName", # required
    #         cache_control: "CacheControl",
    #         content_disposition: "ContentDisposition",
    #         content_encoding: "ContentEncoding",
    #         content_language: "ContentLanguage",
    #         content_type: "ContentType",
    #         copy_source: "CopySource", # required
    #         copy_source_if_match: "CopySourceIfMatch",
    #         copy_source_if_modified_since: Time.now,
    #         copy_source_if_none_match: "CopySourceIfNoneMatch",
    #         copy_source_if_unmodified_since: Time.now,
    #         expires: Time.now,
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write_acp: "GrantWriteACP",
    #         key: "ObjectKey", # required
    #         metadata: {
    #           "MetadataKey" => "MetadataValue",
    #         },
    #         metadata_directive: "COPY", # accepts COPY, REPLACE
    #         tagging_directive: "COPY", # accepts COPY, REPLACE
    #         server_side_encryption: "AES256", # accepts AES256, aws:kms
    #         storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #         website_redirect_location: "WebsiteRedirectLocation",
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         ssekms_key_id: "SSEKMSKeyId",
    #         ssekms_encryption_context: "SSEKMSEncryptionContext",
    #         copy_source_sse_customer_algorithm: "CopySourceSSECustomerAlgorithm",
    #         copy_source_sse_customer_key: "CopySourceSSECustomerKey",
    #         copy_source_sse_customer_key_md5: "CopySourceSSECustomerKeyMD5",
    #         request_payer: "requester", # accepts requester
    #         tagging: "TaggingHeader",
    #         object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #         object_lock_retain_until_date: Time.now,
    #         object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #         expected_bucket_owner: "AccountId",
    #         expected_source_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the object.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the destination bucket.
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] copy_source
    #   Specifies the source object for the copy operation. You specify the
    #   value in one of two formats, depending on whether you want to access
    #   the source object through an [access point][1]\:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and the key of the source object, separated
    #     by a slash (/). For example, to copy the object
    #     `reports/january.pdf` from the bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be URL
    #     encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     access point `my-access-point` owned by account `123456789012` in
    #     Region `us-west-2`, use the URL encoding of
    #     `arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf`.
    #     The value must be URL encoded.
    #
    #     <note markdown="1"> Amazon S3 supports copy operations using access points only when
    #     the source and destination buckets are in the same AWS Region.
    #
    #      </note>
    #
    #   To copy a specific version of an object, append
    #   `?versionId=<version-id>` to the value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified
    #   tag.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #   @return [Time]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to read the object data and its metadata.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the object ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key of the destination object.
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] metadata_directive
    #   Specifies whether the metadata is copied from the source object or
    #   replaced with metadata provided in the request.
    #   @return [String]
    #
    # @!attribute [rw] tagging_directive
    #   Specifies whether the object tag-set are copied from the source
    #   object or replaced with tag-set provided in the request.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   The type of storage to use for the object. Defaults to 'STANDARD'.
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   Specifies the AWS KMS key ID to use for object encryption. All GET
    #   and PUT requests for an object protected by AWS KMS will fail if not
    #   made via SSL or using SigV4. For information about configuring using
    #   any of the officially supported AWS SDKs and AWS CLI, see
    #   [Specifying the Signature Version in Request Authentication][1] in
    #   the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the AWS KMS Encryption Context to use for object
    #   encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object
    #   (for example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   to decrypt the source object. The encryption key provided in this
    #   header must be one that was used when the source object was created.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object destination object this value must be
    #   used in conjunction with the `TaggingDirective`. The tag-set must be
    #   encoded as URL Query parameters.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode that you want to apply to the copied object.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when you want the copied object's Object Lock to
    #   expire.
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether you want to apply a Legal Hold to the copied
    #   object.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected destination bucket owner. If the
    #   destination bucket is owned by a different account, the request will
    #   fail with an HTTP `403 (Access Denied)` error.
    #   @return [String]
    #
    # @!attribute [rw] expected_source_bucket_owner
    #   The account id of the expected source bucket owner. If the source
    #   bucket is owned by a different account, the request will fail with
    #   an HTTP `403 (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectRequest AWS API Documentation
    #
    class CopyObjectRequest < Struct.new(
      :acl,
      :bucket,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :copy_source,
      :copy_source_if_match,
      :copy_source_if_modified_since,
      :copy_source_if_none_match,
      :copy_source_if_unmodified_since,
      :expires,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :key,
      :metadata,
      :metadata_directive,
      :tagging_directive,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :copy_source_sse_customer_algorithm,
      :copy_source_sse_customer_key,
      :copy_source_sse_customer_key_md5,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner,
      :expected_source_bucket_owner)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context, :copy_source_sse_customer_key]
      include Aws::Structure
    end

    # Container for all response elements.
    #
    # @!attribute [rw] etag
    #   Returns the ETag of the new object. The ETag reflects only changes
    #   to the contents of an object, not its metadata. The source and
    #   destination ETag is identical for a successfully copied object.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Returns the date that the object was last modified.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObjectResult AWS API Documentation
    #
    class CopyObjectResult < Struct.new(
      :etag,
      :last_modified)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all response elements.
    #
    # @!attribute [rw] etag
    #   Entity tag of the object.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Date and time at which the object was uploaded.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyPartResult AWS API Documentation
    #
    class CopyPartResult < Struct.new(
      :etag,
      :last_modified)
      SENSITIVE = []
      include Aws::Structure
    end

    # The configuration information for the bucket.
    #
    # @note When making an API call, you may pass CreateBucketConfiguration
    #   data as a hash:
    #
    #       {
    #         location_constraint: "af-south-1", # accepts af-south-1, ap-east-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1, ap-southeast-1, ap-southeast-2, ca-central-1, cn-north-1, cn-northwest-1, EU, eu-central-1, eu-north-1, eu-south-1, eu-west-1, eu-west-2, eu-west-3, me-south-1, sa-east-1, us-east-2, us-gov-east-1, us-gov-west-1, us-west-1, us-west-2
    #       }
    #
    # @!attribute [rw] location_constraint
    #   Specifies the Region where the bucket will be created. If you don't
    #   specify a Region, the bucket is created in the US East (N. Virginia)
    #   Region (us-east-1).
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketConfiguration AWS API Documentation
    #
    class CreateBucketConfiguration < Struct.new(
      :location_constraint)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location
    #   Specifies the Region where the bucket will be created. If you are
    #   creating a bucket on the US East (N. Virginia) Region (us-east-1),
    #   you do not need to specify the location.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketOutput AWS API Documentation
    #
    class CreateBucketOutput < Struct.new(
      :location)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass CreateBucketRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #         bucket: "BucketName", # required
    #         create_bucket_configuration: {
    #           location_constraint: "af-south-1", # accepts af-south-1, ap-east-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1, ap-southeast-1, ap-southeast-2, ca-central-1, cn-north-1, cn-northwest-1, EU, eu-central-1, eu-north-1, eu-south-1, eu-west-1, eu-west-2, eu-west-3, me-south-1, sa-east-1, us-east-2, us-gov-east-1, us-gov-west-1, us-west-1, us-west-2
    #         },
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write: "GrantWrite",
    #         grant_write_acp: "GrantWriteACP",
    #         object_lock_enabled_for_bucket: false,
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the bucket.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to create.
    #   @return [String]
    #
    # @!attribute [rw] create_bucket_configuration
    #   The configuration information for the bucket.
    #   @return [Types::CreateBucketConfiguration]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create, overwrite, and delete any object in the
    #   bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_enabled_for_bucket
    #   Specifies whether you want S3 Object Lock to be enabled for the new
    #   bucket.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucketRequest AWS API Documentation
    #
    class CreateBucketRequest < Struct.new(
      :acl,
      :bucket,
      :create_bucket_configuration,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :object_lock_enabled_for_bucket)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] abort_date
    #   If the bucket has a lifecycle rule configured with an action to
    #   abort incomplete multipart uploads and the prefix in the lifecycle
    #   rule matches the object name in the request, the response includes
    #   this header. The header indicates when the initiated multipart
    #   upload becomes eligible for an abort operation. For more
    #   information, see [ Aborting Incomplete Multipart Uploads Using a
    #   Bucket Lifecycle Policy][1].
    #
    #   The response also includes the `x-amz-abort-rule-id` header that
    #   provides the ID of the lifecycle configuration rule that defines
    #   this action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Time]
    #
    # @!attribute [rw] abort_rule_id
    #   This header is returned along with the `x-amz-abort-date` header. It
    #   identifies the applicable lifecycle configuration rule that defines
    #   the action to abort incomplete multipart uploads.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   ID for the initiated multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, specifies the AWS KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded
    #   UTF-8 string holding JSON with the encryption context key-value
    #   pairs.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateMultipartUploadOutput AWS API Documentation
    #
    class CreateMultipartUploadOutput < Struct.new(
      :abort_date,
      :abort_rule_id,
      :bucket,
      :key,
      :upload_id,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :request_charged)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @note When making an API call, you may pass CreateMultipartUploadRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #         bucket: "BucketName", # required
    #         cache_control: "CacheControl",
    #         content_disposition: "ContentDisposition",
    #         content_encoding: "ContentEncoding",
    #         content_language: "ContentLanguage",
    #         content_type: "ContentType",
    #         expires: Time.now,
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write_acp: "GrantWriteACP",
    #         key: "ObjectKey", # required
    #         metadata: {
    #           "MetadataKey" => "MetadataValue",
    #         },
    #         server_side_encryption: "AES256", # accepts AES256, aws:kms
    #         storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #         website_redirect_location: "WebsiteRedirectLocation",
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         ssekms_key_id: "SSEKMSKeyId",
    #         ssekms_encryption_context: "SSEKMSEncryptionContext",
    #         request_payer: "requester", # accepts requester
    #         tagging: "TaggingHeader",
    #         object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #         object_lock_retain_until_date: Time.now,
    #         object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the object.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to which to initiate the upload
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to read the object data and its metadata.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the object ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload is to be initiated.
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   The type of storage to use for the object. Defaults to 'STANDARD'.
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   Specifies the ID of the symmetric customer managed AWS KMS CMK to
    #   use for object encryption. All GET and PUT requests for an object
    #   protected by AWS KMS will fail if not made via SSL or using SigV4.
    #   For information about configuring using any of the officially
    #   supported AWS SDKs and AWS CLI, see [Specifying the Signature
    #   Version in Request Authentication][1] in the *Amazon S3 Developer
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/http:/docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the AWS KMS Encryption Context to use for object
    #   encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   Specifies the Object Lock mode that you want to apply to the
    #   uploaded object.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   Specifies the date and time when you want the Object Lock to expire.
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether you want to apply a Legal Hold to the uploaded
    #   object.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateMultipartUploadRequest AWS API Documentation
    #
    class CreateMultipartUploadRequest < Struct.new(
      :acl,
      :bucket,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :expires,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :key,
      :metadata,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # The container element for specifying the default Object Lock retention
    # settings for new objects placed in the specified bucket.
    #
    # @note When making an API call, you may pass DefaultRetention
    #   data as a hash:
    #
    #       {
    #         mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #         days: 1,
    #         years: 1,
    #       }
    #
    # @!attribute [rw] mode
    #   The default Object Lock retention mode you want to apply to new
    #   objects placed in the specified bucket.
    #   @return [String]
    #
    # @!attribute [rw] days
    #   The number of days that you want to specify for the default
    #   retention period.
    #   @return [Integer]
    #
    # @!attribute [rw] years
    #   The number of years that you want to specify for the default
    #   retention period.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DefaultRetention AWS API Documentation
    #
    class DefaultRetention < Struct.new(
      :mode,
      :days,
      :years)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the objects to delete.
    #
    # @note When making an API call, you may pass Delete
    #   data as a hash:
    #
    #       {
    #         objects: [ # required
    #           {
    #             key: "ObjectKey", # required
    #             version_id: "ObjectVersionId",
    #           },
    #         ],
    #         quiet: false,
    #       }
    #
    # @!attribute [rw] objects
    #   The objects to delete.
    #   @return [Array<Types::ObjectIdentifier>]
    #
    # @!attribute [rw] quiet
    #   Element to enable quiet mode for the request. When you add this
    #   element, you must set its value to true.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Delete AWS API Documentation
    #
    class Delete < Struct.new(
      :objects,
      :quiet)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketAnalyticsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "AnalyticsId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket from which an analytics configuration is
    #   deleted.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class DeleteBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketCorsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Specifies the bucket whose `cors` configuration is being deleted.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketCorsRequest AWS API Documentation
    #
    class DeleteBucketCorsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketEncryptionRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the server-side encryption
    #   configuration to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketEncryptionRequest AWS API Documentation
    #
    class DeleteBucketEncryptionRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketInventoryConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "InventoryId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configuration to
    #   delete.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketInventoryConfigurationRequest AWS API Documentation
    #
    class DeleteBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketLifecycleRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name of the lifecycle to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketLifecycleRequest AWS API Documentation
    #
    class DeleteBucketLifecycleRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketMetricsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "MetricsId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configuration to
    #   delete.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketMetricsConfigurationRequest AWS API Documentation
    #
    class DeleteBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketPolicyRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketPolicyRequest AWS API Documentation
    #
    class DeleteBucketPolicyRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketReplicationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketReplicationRequest AWS API Documentation
    #
    class DeleteBucketReplicationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Specifies the bucket being deleted.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketRequest AWS API Documentation
    #
    class DeleteBucketRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket that has the tag set to be removed.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketTaggingRequest AWS API Documentation
    #
    class DeleteBucketTaggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteBucketWebsiteRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which you want to remove the website
    #   configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketWebsiteRequest AWS API Documentation
    #
    class DeleteBucketWebsiteRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Information about the delete marker.
    #
    # @!attribute [rw] owner
    #   The account that created the delete marker.&gt;
    #   @return [Types::Owner]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of an object.
    #   @return [String]
    #
    # @!attribute [rw] is_latest
    #   Specifies whether the object is (true) or is not (false) the latest
    #   version of an object.
    #   @return [Boolean]
    #
    # @!attribute [rw] last_modified
    #   Date and time the object was last modified.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteMarkerEntry AWS API Documentation
    #
    class DeleteMarkerEntry < Struct.new(
      :owner,
      :key,
      :version_id,
      :is_latest,
      :last_modified)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies whether Amazon S3 replicates the delete markers. If you
    # specify a `Filter`, you must specify this element. However, in the
    # latest version of replication configuration (when `Filter` is
    # specified), Amazon S3 doesn't replicate delete markers. Therefore,
    # the `DeleteMarkerReplication` element can contain only
    # &lt;Status&gt;Disabled&lt;/Status&gt;. For an example configuration,
    # see [Basic Rule Configuration][1].
    #
    # <note markdown="1"> If you don't specify the `Filter` element, Amazon S3 assumes that the
    # replication configuration is the earlier version, V1. In the earlier
    # version, Amazon S3 handled replication of delete markers differently.
    # For more information, see [Backward Compatibility][2].
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-config-min-rule-config
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations
    #
    # @note When making an API call, you may pass DeleteMarkerReplication
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # accepts Enabled, Disabled
    #       }
    #
    # @!attribute [rw] status
    #   Indicates whether to replicate delete markers.
    #
    #   <note markdown="1"> In the current implementation, Amazon S3 doesn't replicate the
    #   delete markers. The status must be `Disabled`.
    #
    #    </note>
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteMarkerReplication AWS API Documentation
    #
    class DeleteMarkerReplication < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] delete_marker
    #   Specifies whether the versioned object that was permanently deleted
    #   was (true) or was not (false) a delete marker.
    #   @return [Boolean]
    #
    # @!attribute [rw] version_id
    #   Returns the version ID of the delete marker created as a result of
    #   the DELETE operation.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectOutput AWS API Documentation
    #
    class DeleteObjectOutput < Struct.new(
      :delete_marker,
      :version_id,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteObjectRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         mfa: "MFA",
    #         version_id: "ObjectVersionId",
    #         request_payer: "requester", # accepts requester
    #         bypass_governance_retention: false,
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name of the bucket containing the object.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key name of the object to delete.
    #   @return [String]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device. Required to permanently delete a versioned object if
    #   versioning is configured with MFA delete enabled.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Indicates whether S3 Object Lock should bypass Governance-mode
    #   restrictions to process this operation.
    #   @return [Boolean]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectRequest AWS API Documentation
    #
    class DeleteObjectRequest < Struct.new(
      :bucket,
      :key,
      :mfa,
      :version_id,
      :request_payer,
      :bypass_governance_retention,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object the tag-set was removed from.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectTaggingOutput AWS API Documentation
    #
    class DeleteObjectTaggingOutput < Struct.new(
      :version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteObjectTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the objects from which to remove the
    #   tags.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Name of the object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object that the tag-set will be removed from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectTaggingRequest AWS API Documentation
    #
    class DeleteObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] deleted
    #   Container element for a successful delete. It identifies the object
    #   that was successfully deleted.
    #   @return [Array<Types::DeletedObject>]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @!attribute [rw] errors
    #   Container for a failed delete operation that describes the object
    #   that Amazon S3 attempted to delete and the error it encountered.
    #   @return [Array<Types::Error>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectsOutput AWS API Documentation
    #
    class DeleteObjectsOutput < Struct.new(
      :deleted,
      :request_charged,
      :errors)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteObjectsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         delete: { # required
    #           objects: [ # required
    #             {
    #               key: "ObjectKey", # required
    #               version_id: "ObjectVersionId",
    #             },
    #           ],
    #           quiet: false,
    #         },
    #         mfa: "MFA",
    #         request_payer: "requester", # accepts requester
    #         bypass_governance_retention: false,
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the objects to delete.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] delete
    #   Container for the request.
    #   @return [Types::Delete]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device. Required to permanently delete a versioned object if
    #   versioning is configured with MFA delete enabled.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Specifies whether you want to delete this object even if it has a
    #   Governance-type Object Lock in place. You must have sufficient
    #   permissions to perform this operation.
    #   @return [Boolean]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectsRequest AWS API Documentation
    #
    class DeleteObjectsRequest < Struct.new(
      :bucket,
      :delete,
      :mfa,
      :request_payer,
      :bypass_governance_retention,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeletePublicAccessBlockRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The Amazon S3 bucket whose `PublicAccessBlock` configuration you
    #   want to delete.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeletePublicAccessBlockRequest AWS API Documentation
    #
    class DeletePublicAccessBlockRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Information about the deleted object.
    #
    # @!attribute [rw] key
    #   The name of the deleted object.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the deleted object.
    #   @return [String]
    #
    # @!attribute [rw] delete_marker
    #   Specifies whether the versioned object that was permanently deleted
    #   was (true) or was not (false) a delete marker. In a simple DELETE,
    #   this header indicates whether (true) or not (false) a delete marker
    #   was created.
    #   @return [Boolean]
    #
    # @!attribute [rw] delete_marker_version_id
    #   The version ID of the delete marker created as a result of the
    #   DELETE operation. If you delete a specific object version, the value
    #   returned by this header is the version ID of the object version
    #   deleted.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeletedObject AWS API Documentation
    #
    class DeletedObject < Struct.new(
      :key,
      :version_id,
      :delete_marker,
      :delete_marker_version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies information about where to publish analysis or configuration
    # results for an Amazon S3 bucket and S3 Replication Time Control (S3
    # RTC).
    #
    # @note When making an API call, you may pass Destination
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         account: "AccountId",
    #         storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #         access_control_translation: {
    #           owner: "Destination", # required, accepts Destination
    #         },
    #         encryption_configuration: {
    #           replica_kms_key_id: "ReplicaKmsKeyID",
    #         },
    #         replication_time: {
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           time: { # required
    #             minutes: 1,
    #           },
    #         },
    #         metrics: {
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           event_threshold: { # required
    #             minutes: 1,
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket where you want Amazon
    #   S3 to store the results.
    #   @return [String]
    #
    # @!attribute [rw] account
    #   Destination bucket owner account ID. In a cross-account scenario, if
    #   you direct Amazon S3 to change replica ownership to the AWS account
    #   that owns the destination bucket by specifying the
    #   `AccessControlTranslation` property, this is the account ID of the
    #   destination bucket owner. For more information, see [Replication
    #   Additional Configuration: Changing the Replica Owner][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-change-owner.html
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   The storage class to use when replicating objects, such as S3
    #   Standard or reduced redundancy. By default, Amazon S3 uses the
    #   storage class of the source object to create the object replica.
    #
    #   For valid values, see the `StorageClass` element of the [PUT Bucket
    #   replication][1] action in the *Amazon Simple Storage Service API
    #   Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTreplication.html
    #   @return [String]
    #
    # @!attribute [rw] access_control_translation
    #   Specify this only in a cross-account scenario (where source and
    #   destination bucket owners are not the same), and you want to change
    #   replica ownership to the AWS account that owns the destination
    #   bucket. If this is not specified in the replication configuration,
    #   the replicas are owned by same AWS account that owns the source
    #   object.
    #   @return [Types::AccessControlTranslation]
    #
    # @!attribute [rw] encryption_configuration
    #   A container that provides information about encryption. If
    #   `SourceSelectionCriteria` is specified, you must specify this
    #   element.
    #   @return [Types::EncryptionConfiguration]
    #
    # @!attribute [rw] replication_time
    #   A container specifying S3 Replication Time Control (S3 RTC),
    #   including whether S3 RTC is enabled and the time when all objects
    #   and operations on objects must be replicated. Must be specified
    #   together with a `Metrics` block.
    #   @return [Types::ReplicationTime]
    #
    # @!attribute [rw] metrics
    #   A container specifying replication metrics-related settings enabling
    #   metrics and Amazon S3 events for S3 Replication Time Control (S3
    #   RTC). Must be specified together with a `ReplicationTime` block.
    #   @return [Types::Metrics]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Destination AWS API Documentation
    #
    class Destination < Struct.new(
      :bucket,
      :account,
      :storage_class,
      :access_control_translation,
      :encryption_configuration,
      :replication_time,
      :metrics)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the type of server-side encryption used.
    #
    # @note When making an API call, you may pass Encryption
    #   data as a hash:
    #
    #       {
    #         encryption_type: "AES256", # required, accepts AES256, aws:kms
    #         kms_key_id: "SSEKMSKeyId",
    #         kms_context: "KMSContext",
    #       }
    #
    # @!attribute [rw] encryption_type
    #   The server-side encryption algorithm used when storing job results
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] kms_key_id
    #   If the encryption type is `aws:kms`, this optional value specifies
    #   the ID of the symmetric customer managed AWS KMS CMK to use for
    #   encryption of job results. Amazon S3 only supports symmetric CMKs.
    #   For more information, see [Using Symmetric and Asymmetric Keys][1]
    #   in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @!attribute [rw] kms_context
    #   If the encryption type is `aws:kms`, this optional value can be used
    #   to specify the encryption context for the restore results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Encryption AWS API Documentation
    #
    class Encryption < Struct.new(
      :encryption_type,
      :kms_key_id,
      :kms_context)
      SENSITIVE = [:kms_key_id]
      include Aws::Structure
    end

    # Specifies encryption-related information for an Amazon S3 bucket that
    # is a destination for replicated objects.
    #
    # @note When making an API call, you may pass EncryptionConfiguration
    #   data as a hash:
    #
    #       {
    #         replica_kms_key_id: "ReplicaKmsKeyID",
    #       }
    #
    # @!attribute [rw] replica_kms_key_id
    #   Specifies the ID (Key ARN or Alias ARN) of the customer managed
    #   customer master key (CMK) stored in AWS Key Management Service (KMS)
    #   for the destination bucket. Amazon S3 uses this key to encrypt
    #   replica objects. Amazon S3 only supports symmetric customer managed
    #   CMKs. For more information, see [Using Symmetric and Asymmetric
    #   Keys][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EncryptionConfiguration AWS API Documentation
    #
    class EncryptionConfiguration < Struct.new(
      :replica_kms_key_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # A message that indicates the request is complete and no more messages
    # will be sent. You should not assume that the request is complete until
    # the client receives an `EndEvent`.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/EndEvent AWS API Documentation
    #
    class EndEvent < Struct.new(
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for all error elements.
    #
    # @!attribute [rw] key
    #   The error key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the error.
    #   @return [String]
    #
    # @!attribute [rw] code
    #   The error code is a string that uniquely identifies an error
    #   condition. It is meant to be read and understood by programs that
    #   detect and handle errors by type.
    #
    #   **Amazon S3 error codes**
    #
    #   * * *Code:* AccessDenied
    #
    #     * *Description:* Access Denied
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* AccountProblem
    #
    #     * *Description:* There is a problem with your AWS account that
    #       prevents the operation from completing successfully. Contact AWS
    #       Support for further assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* AllAccessDisabled
    #
    #     * *Description:* All access to this Amazon S3 resource has been
    #       disabled. Contact AWS Support for further assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* AmbiguousGrantByEmailAddress
    #
    #     * *Description:* The email address you provided is associated with
    #       more than one account.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* AuthorizationHeaderMalformed
    #
    #     * *Description:* The authorization header you provided is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *HTTP Status Code:* N/A
    #
    #   * * *Code:* BadDigest
    #
    #     * *Description:* The Content-MD5 you specified did not match what
    #       we received.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* BucketAlreadyExists
    #
    #     * *Description:* The requested bucket name is not available. The
    #       bucket namespace is shared by all users of the system. Please
    #       select a different name and try again.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* BucketAlreadyOwnedByYou
    #
    #     * *Description:* The bucket you tried to create already exists,
    #       and you own it. Amazon S3 returns this error in all AWS Regions
    #       except in the North Virginia Region. For legacy compatibility,
    #       if you re-create an existing bucket that you already own in the
    #       North Virginia Region, Amazon S3 returns 200 OK and resets the
    #       bucket access control lists (ACLs).
    #
    #     * *Code:* 409 Conflict (in all Regions except the North Virginia
    #       Region)
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* BucketNotEmpty
    #
    #     * *Description:* The bucket you tried to delete is not empty.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* CredentialsNotSupported
    #
    #     * *Description:* This request does not support credentials.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* CrossLocationLoggingProhibited
    #
    #     * *Description:* Cross-location logging not allowed. Buckets in
    #       one geographic location cannot log information to a bucket in
    #       another location.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* EntityTooSmall
    #
    #     * *Description:* Your proposed upload is smaller than the minimum
    #       allowed object size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* EntityTooLarge
    #
    #     * *Description:* Your proposed upload exceeds the maximum allowed
    #       object size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* ExpiredToken
    #
    #     * *Description:* The provided token has expired.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* IllegalVersioningConfigurationException
    #
    #     * *Description:* Indicates that the versioning configuration
    #       specified in the request is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* IncompleteBody
    #
    #     * *Description:* You did not provide the number of bytes specified
    #       by the Content-Length HTTP header
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* IncorrectNumberOfFilesInPostRequest
    #
    #     * *Description:* POST requires exactly one file upload per
    #       request.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InlineDataTooLarge
    #
    #     * *Description:* Inline data exceeds the maximum allowed size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InternalError
    #
    #     * *Description:* We encountered an internal error. Please try
    #       again.
    #
    #     * *HTTP Status Code:* 500 Internal Server Error
    #
    #     * *SOAP Fault Code Prefix:* Server
    #
    #   * * *Code:* InvalidAccessKeyId
    #
    #     * *Description:* The AWS access key ID you provided does not exist
    #       in our records.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidAddressingHeader
    #
    #     * *Description:* You must specify the Anonymous role.
    #
    #     * *HTTP Status Code:* N/A
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidArgument
    #
    #     * *Description:* Invalid Argument
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidBucketName
    #
    #     * *Description:* The specified bucket is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidBucketState
    #
    #     * *Description:* The request is not valid with the current state
    #       of the bucket.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidDigest
    #
    #     * *Description:* The Content-MD5 you specified is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidEncryptionAlgorithmError
    #
    #     * *Description:* The encryption request you specified is not
    #       valid. The valid value is AES256.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidLocationConstraint
    #
    #     * *Description:* The specified location constraint is not valid.
    #       For more information about Regions, see [How to Select a Region
    #       for Your Buckets][1].
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidObjectState
    #
    #     * *Description:* The operation is not valid for the current state
    #       of the object.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidPart
    #
    #     * *Description:* One or more of the specified parts could not be
    #       found. The part might not have been uploaded, or the specified
    #       entity tag might not have matched the part's entity tag.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidPartOrder
    #
    #     * *Description:* The list of parts was not in ascending order.
    #       Parts list must be specified in order by part number.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidPayer
    #
    #     * *Description:* All access to this object has been disabled.
    #       Please contact AWS Support for further assistance.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidPolicyDocument
    #
    #     * *Description:* The content of the form does not meet the
    #       conditions specified in the policy document.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidRange
    #
    #     * *Description:* The requested range cannot be satisfied.
    #
    #     * *HTTP Status Code:* 416 Requested Range Not Satisfiable
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Please use AWS4-HMAC-SHA256.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* SOAP requests must be made over an HTTPS
    #       connection.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       for buckets with non-DNS compliant names.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       for buckets with periods (.) in their names.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate endpoint only
    #       supports virtual style requests.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate is not configured
    #       on this bucket.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Accelerate is disabled on this
    #       bucket.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration is not supported
    #       on this bucket. Contact AWS Support for more information.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidRequest
    #
    #     * *Description:* Amazon S3 Transfer Acceleration cannot be enabled
    #       on this bucket. Contact AWS Support for more information.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *Code:* N/A
    #
    #   * * *Code:* InvalidSecurity
    #
    #     * *Description:* The provided security credentials are not valid.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidSOAPRequest
    #
    #     * *Description:* The SOAP request body is invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidStorageClass
    #
    #     * *Description:* The storage class you specified is not valid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidTargetBucketForLogging
    #
    #     * *Description:* The target bucket for logging does not exist, is
    #       not owned by you, or does not have the appropriate grants for
    #       the log-delivery group.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidToken
    #
    #     * *Description:* The provided token is malformed or otherwise
    #       invalid.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* InvalidURI
    #
    #     * *Description:* Couldn't parse the specified URI.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* KeyTooLongError
    #
    #     * *Description:* Your key is too long.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MalformedACLError
    #
    #     * *Description:* The XML you provided was not well-formed or did
    #       not validate against our published schema.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MalformedPOSTRequest
    #
    #     * *Description:* The body of your POST request is not well-formed
    #       multipart/form-data.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MalformedXML
    #
    #     * *Description:* This happens when the user sends malformed XML
    #       (XML that doesn't conform to the published XSD) for the
    #       configuration. The error message is, "The XML you provided was
    #       not well-formed or did not validate against our published
    #       schema."
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MaxMessageLengthExceeded
    #
    #     * *Description:* Your request was too big.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MaxPostPreDataLengthExceededError
    #
    #     * *Description:* Your POST request fields preceding the upload
    #       file were too large.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MetadataTooLarge
    #
    #     * *Description:* Your metadata headers exceed the maximum allowed
    #       metadata size.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MethodNotAllowed
    #
    #     * *Description:* The specified method is not allowed against this
    #       resource.
    #
    #     * *HTTP Status Code:* 405 Method Not Allowed
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MissingAttachment
    #
    #     * *Description:* A SOAP attachment was expected, but none were
    #       found.
    #
    #     * *HTTP Status Code:* N/A
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MissingContentLength
    #
    #     * *Description:* You must provide the Content-Length HTTP header.
    #
    #     * *HTTP Status Code:* 411 Length Required
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MissingRequestBodyError
    #
    #     * *Description:* This happens when the user sends an empty XML
    #       document as a request. The error message is, "Request body is
    #       empty."
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MissingSecurityElement
    #
    #     * *Description:* The SOAP 1.1 request is missing a security
    #       element.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* MissingSecurityHeader
    #
    #     * *Description:* Your request is missing a required header.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoLoggingStatusForKey
    #
    #     * *Description:* There is no such thing as a logging status
    #       subresource for a key.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchBucket
    #
    #     * *Description:* The specified bucket does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchBucketPolicy
    #
    #     * *Description:* The specified bucket does not have a bucket
    #       policy.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchKey
    #
    #     * *Description:* The specified key does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchLifecycleConfiguration
    #
    #     * *Description:* The lifecycle configuration does not exist.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchUpload
    #
    #     * *Description:* The specified multipart upload does not exist.
    #       The upload ID might be invalid, or the multipart upload might
    #       have been aborted or completed.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NoSuchVersion
    #
    #     * *Description:* Indicates that the version ID specified in the
    #       request does not match an existing version.
    #
    #     * *HTTP Status Code:* 404 Not Found
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* NotImplemented
    #
    #     * *Description:* A header you provided implies functionality that
    #       is not implemented.
    #
    #     * *HTTP Status Code:* 501 Not Implemented
    #
    #     * *SOAP Fault Code Prefix:* Server
    #
    #   * * *Code:* NotSignedUp
    #
    #     * *Description:* Your account is not signed up for the Amazon S3
    #       service. You must sign up before you can use Amazon S3. You can
    #       sign up at the following URL: https://aws.amazon.com/s3
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* OperationAborted
    #
    #     * *Description:* A conflicting conditional operation is currently
    #       in progress against this resource. Try again.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* PermanentRedirect
    #
    #     * *Description:* The bucket you are attempting to access must be
    #       addressed using the specified endpoint. Send all future requests
    #       to this endpoint.
    #
    #     * *HTTP Status Code:* 301 Moved Permanently
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* PreconditionFailed
    #
    #     * *Description:* At least one of the preconditions you specified
    #       did not hold.
    #
    #     * *HTTP Status Code:* 412 Precondition Failed
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* Redirect
    #
    #     * *Description:* Temporary redirect.
    #
    #     * *HTTP Status Code:* 307 Moved Temporarily
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* RestoreAlreadyInProgress
    #
    #     * *Description:* Object restore is already in progress.
    #
    #     * *HTTP Status Code:* 409 Conflict
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* RequestIsNotMultiPartContent
    #
    #     * *Description:* Bucket POST must be of the enclosure-type
    #       multipart/form-data.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* RequestTimeout
    #
    #     * *Description:* Your socket connection to the server was not read
    #       from or written to within the timeout period.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* RequestTimeTooSkewed
    #
    #     * *Description:* The difference between the request time and the
    #       server's time is too large.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* RequestTorrentOfBucketError
    #
    #     * *Description:* Requesting the torrent file of a bucket is not
    #       permitted.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* SignatureDoesNotMatch
    #
    #     * *Description:* The request signature we calculated does not
    #       match the signature you provided. Check your AWS secret access
    #       key and signing method. For more information, see [REST
    #       Authentication][2] and [SOAP Authentication][3] for details.
    #
    #     * *HTTP Status Code:* 403 Forbidden
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* ServiceUnavailable
    #
    #     * *Description:* Reduce your request rate.
    #
    #     * *HTTP Status Code:* 503 Service Unavailable
    #
    #     * *SOAP Fault Code Prefix:* Server
    #
    #   * * *Code:* SlowDown
    #
    #     * *Description:* Reduce your request rate.
    #
    #     * *HTTP Status Code:* 503 Slow Down
    #
    #     * *SOAP Fault Code Prefix:* Server
    #
    #   * * *Code:* TemporaryRedirect
    #
    #     * *Description:* You are being redirected to the bucket while DNS
    #       updates.
    #
    #     * *HTTP Status Code:* 307 Moved Temporarily
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* TokenRefreshRequired
    #
    #     * *Description:* The provided token must be refreshed.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* TooManyBuckets
    #
    #     * *Description:* You have attempted to create more buckets than
    #       allowed.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* UnexpectedContent
    #
    #     * *Description:* This request does not support content.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* UnresolvableGrantByEmailAddress
    #
    #     * *Description:* The email address you provided does not match any
    #       account on record.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #   * * *Code:* UserKeyMustBeSpecified
    #
    #     * *Description:* The bucket POST must contain the specified field
    #       name. If it is specified, check the order of the fields.
    #
    #     * *HTTP Status Code:* 400 Bad Request
    #
    #     * *SOAP Fault Code Prefix:* Client
    #
    #
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/SOAPAuthentication.html
    #   @return [String]
    #
    # @!attribute [rw] message
    #   The error message contains a generic description of the error
    #   condition in English. It is intended for a human audience. Simple
    #   programs display the message directly to the end user if they
    #   encounter an error condition they don't know how or don't care to
    #   handle. Sophisticated programs with more exhaustive error handling
    #   and proper internationalization are more likely to ignore the error
    #   message.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Error AWS API Documentation
    #
    class Error < Struct.new(
      :key,
      :version_id,
      :code,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The error information.
    #
    # @note When making an API call, you may pass ErrorDocument
    #   data as a hash:
    #
    #       {
    #         key: "ObjectKey", # required
    #       }
    #
    # @!attribute [rw] key
    #   The object key name to use when a 4XX class error occurs.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ErrorDocument AWS API Documentation
    #
    class ErrorDocument < Struct.new(
      :key)
      SENSITIVE = []
      include Aws::Structure
    end

    # Optional configuration to replicate existing source bucket objects.
    # For more information, see [Replicating Existing Objects](
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-what-is-isnot-replicated.html#existing-object-replication)
    # in the *Amazon S3 Developer Guide*.
    #
    # @note When making an API call, you may pass ExistingObjectReplication
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #       }
    #
    # @!attribute [rw] status
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ExistingObjectReplication AWS API Documentation
    #
    class ExistingObjectReplication < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the Amazon S3 object key name to filter on and whether to
    # filter on the suffix or prefix of the key name.
    #
    # @note When making an API call, you may pass FilterRule
    #   data as a hash:
    #
    #       {
    #         name: "prefix", # accepts prefix, suffix
    #         value: "FilterRuleValue",
    #       }
    #
    # @!attribute [rw] name
    #   The object key name prefix or suffix identifying one or more objects
    #   to which the filtering rule applies. The maximum length is 1,024
    #   characters. Overlapping prefixes and suffixes are not supported. For
    #   more information, see [Configuring Event Notifications][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [String]
    #
    # @!attribute [rw] value
    #   The value that the filter searches for in object key names.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/FilterRule AWS API Documentation
    #
    class FilterRule < Struct.new(
      :name,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] status
    #   The accelerate configuration of the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAccelerateConfigurationOutput AWS API Documentation
    #
    class GetBucketAccelerateConfigurationOutput < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketAccelerateConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket for which the accelerate configuration is
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAccelerateConfigurationRequest AWS API Documentation
    #
    class GetBucketAccelerateConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] owner
    #   Container for the bucket owner's display name and ID.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAclOutput AWS API Documentation
    #
    class GetBucketAclOutput < Struct.new(
      :owner,
      :grants)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketAclRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Specifies the S3 bucket whose ACL is being requested.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAclRequest AWS API Documentation
    #
    class GetBucketAclRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] analytics_configuration
    #   The configuration and any analyses for the analytics filter.
    #   @return [Types::AnalyticsConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAnalyticsConfigurationOutput AWS API Documentation
    #
    class GetBucketAnalyticsConfigurationOutput < Struct.new(
      :analytics_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketAnalyticsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "AnalyticsId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket from which an analytics configuration is
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class GetBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] cors_rules
    #   A set of origins and methods (cross-origin access that you want to
    #   allow). You can add up to 100 rules to the configuration.
    #   @return [Array<Types::CORSRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketCorsOutput AWS API Documentation
    #
    class GetBucketCorsOutput < Struct.new(
      :cors_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketCorsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which to get the cors configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketCorsRequest AWS API Documentation
    #
    class GetBucketCorsRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] server_side_encryption_configuration
    #   Specifies the default server-side-encryption configuration.
    #   @return [Types::ServerSideEncryptionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketEncryptionOutput AWS API Documentation
    #
    class GetBucketEncryptionOutput < Struct.new(
      :server_side_encryption_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketEncryptionRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket from which the server-side encryption
    #   configuration is retrieved.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketEncryptionRequest AWS API Documentation
    #
    class GetBucketEncryptionRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] inventory_configuration
    #   Specifies the inventory configuration.
    #   @return [Types::InventoryConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketInventoryConfigurationOutput AWS API Documentation
    #
    class GetBucketInventoryConfigurationOutput < Struct.new(
      :inventory_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketInventoryConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "InventoryId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configuration to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketInventoryConfigurationRequest AWS API Documentation
    #
    class GetBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] rules
    #   Container for a lifecycle rule.
    #   @return [Array<Types::LifecycleRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleConfigurationOutput AWS API Documentation
    #
    class GetBucketLifecycleConfigurationOutput < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketLifecycleConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the lifecycle information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleConfigurationRequest AWS API Documentation
    #
    class GetBucketLifecycleConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] rules
    #   Container for a lifecycle rule.
    #   @return [Array<Types::Rule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleOutput AWS API Documentation
    #
    class GetBucketLifecycleOutput < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketLifecycleRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the lifecycle information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleRequest AWS API Documentation
    #
    class GetBucketLifecycleRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] location_constraint
    #   Specifies the Region where the bucket resides. For a list of all the
    #   Amazon S3 supported location constraints by Region, see [Regions and
    #   Endpoints][1]. Buckets in Region `us-east-1` have a
    #   LocationConstraint of `null`.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLocationOutput AWS API Documentation
    #
    class GetBucketLocationOutput < Struct.new(
      :location_constraint)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketLocationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the location.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLocationRequest AWS API Documentation
    #
    class GetBucketLocationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] logging_enabled
    #   Describes where logs are stored and the prefix that Amazon S3
    #   assigns to all log object keys for a bucket. For more information,
    #   see [PUT Bucket logging][1] in the *Amazon Simple Storage Service
    #   API Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #   @return [Types::LoggingEnabled]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLoggingOutput AWS API Documentation
    #
    class GetBucketLoggingOutput < Struct.new(
      :logging_enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketLoggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which to get the logging information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLoggingRequest AWS API Documentation
    #
    class GetBucketLoggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] metrics_configuration
    #   Specifies the metrics configuration.
    #   @return [Types::MetricsConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetricsConfigurationOutput AWS API Documentation
    #
    class GetBucketMetricsConfigurationOutput < Struct.new(
      :metrics_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketMetricsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "MetricsId", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configuration to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetricsConfigurationRequest AWS API Documentation
    #
    class GetBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketNotificationConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket for which to get the notification configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketNotificationConfigurationRequest AWS API Documentation
    #
    class GetBucketNotificationConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] policy
    #   The bucket policy as a JSON document.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyOutput AWS API Documentation
    #
    class GetBucketPolicyOutput < Struct.new(
      :policy)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketPolicyRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which to get the bucket policy.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyRequest AWS API Documentation
    #
    class GetBucketPolicyRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] policy_status
    #   The policy status for the specified bucket.
    #   @return [Types::PolicyStatus]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyStatusOutput AWS API Documentation
    #
    class GetBucketPolicyStatusOutput < Struct.new(
      :policy_status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketPolicyStatusRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose policy status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyStatusRequest AWS API Documentation
    #
    class GetBucketPolicyStatusRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] replication_configuration
    #   A container for replication rules. You can add up to 1,000 rules.
    #   The maximum size of a replication configuration is 2 MB.
    #   @return [Types::ReplicationConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketReplicationOutput AWS API Documentation
    #
    class GetBucketReplicationOutput < Struct.new(
      :replication_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketReplicationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which to get the replication information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketReplicationRequest AWS API Documentation
    #
    class GetBucketReplicationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] payer
    #   Specifies who pays for the download and request fees.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketRequestPaymentOutput AWS API Documentation
    #
    class GetBucketRequestPaymentOutput < Struct.new(
      :payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketRequestPaymentRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the payment request
    #   configuration
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketRequestPaymentRequest AWS API Documentation
    #
    class GetBucketRequestPaymentRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] tag_set
    #   Contains the tag set.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketTaggingOutput AWS API Documentation
    #
    class GetBucketTaggingOutput < Struct.new(
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the tagging information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketTaggingRequest AWS API Documentation
    #
    class GetBucketTaggingRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] status
    #   The versioning state of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] mfa_delete
    #   Specifies whether MFA delete is enabled in the bucket versioning
    #   configuration. This element is only returned if the bucket has been
    #   configured with MFA delete. If the bucket has never been so
    #   configured, this element is not returned.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketVersioningOutput AWS API Documentation
    #
    class GetBucketVersioningOutput < Struct.new(
      :status,
      :mfa_delete)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketVersioningRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to get the versioning information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketVersioningRequest AWS API Documentation
    #
    class GetBucketVersioningRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] redirect_all_requests_to
    #   Specifies the redirect behavior of all requests to a website
    #   endpoint of an Amazon S3 bucket.
    #   @return [Types::RedirectAllRequestsTo]
    #
    # @!attribute [rw] index_document
    #   The name of the index document for the website (for example
    #   `index.html`).
    #   @return [Types::IndexDocument]
    #
    # @!attribute [rw] error_document
    #   The object key name of the website error document to use for 4XX
    #   class errors.
    #   @return [Types::ErrorDocument]
    #
    # @!attribute [rw] routing_rules
    #   Rules that define when a redirect is applied and the redirect
    #   behavior.
    #   @return [Array<Types::RoutingRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketWebsiteOutput AWS API Documentation
    #
    class GetBucketWebsiteOutput < Struct.new(
      :redirect_all_requests_to,
      :index_document,
      :error_document,
      :routing_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetBucketWebsiteRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name for which to get the website configuration.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketWebsiteRequest AWS API Documentation
    #
    class GetBucketWebsiteRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] owner
    #   Container for the bucket owner's display name and ID.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAclOutput AWS API Documentation
    #
    class GetObjectAclOutput < Struct.new(
      :owner,
      :grants,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectAclRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name that contains the object for which to get the ACL
    #   information.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key of the object for which to get the ACL information.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAclRequest AWS API Documentation
    #
    class GetObjectAclRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] legal_hold
    #   The current Legal Hold status for the specified object.
    #   @return [Types::ObjectLockLegalHold]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLegalHoldOutput AWS API Documentation
    #
    class GetObjectLegalHoldOutput < Struct.new(
      :legal_hold)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectLegalHoldRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object whose Legal Hold status you
    #   want to retrieve.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object whose Legal Hold status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object whose Legal Hold status you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLegalHoldRequest AWS API Documentation
    #
    class GetObjectLegalHoldRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] object_lock_configuration
    #   The specified bucket's Object Lock configuration.
    #   @return [Types::ObjectLockConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLockConfigurationOutput AWS API Documentation
    #
    class GetObjectLockConfigurationOutput < Struct.new(
      :object_lock_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectLockConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket whose Object Lock configuration you want to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLockConfigurationRequest AWS API Documentation
    #
    class GetObjectLockConfigurationRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] delete_marker
    #   Specifies whether the object retrieved was (true) or was not (false)
    #   a Delete Marker. If false, this response header does not appear in
    #   the response.
    #   @return [Boolean]
    #
    # @!attribute [rw] accept_ranges
    #   Indicates that a range of bytes was specified.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured (see PUT Bucket lifecycle),
    #   the response includes this header. It includes the expiry-date and
    #   rule-id key-value pairs providing object expiration information. The
    #   value of the rule-id is URL encoded.
    #   @return [String]
    #
    # @!attribute [rw] restore
    #   Provides information about object restoration operation and
    #   expiration time of the restored object copy.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Last modified date of the object
    #   @return [Time]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] etag
    #   An ETag is an opaque identifier assigned by a web server to a
    #   specific version of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] missing_meta
    #   This is set to the number of metadata entries not returned in
    #   `x-amz-meta` headers. This can happen if you create metadata using
    #   an API like SOAP that supports more flexible metadata than the REST
    #   API. For example, using SOAP, you can create metadata whose values
    #   are not legal HTTP headers.
    #   @return [Integer]
    #
    # @!attribute [rw] version_id
    #   Version of the object.
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_range
    #   The portion of the object returned in the response.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] expires_string
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @!attribute [rw] replication_status
    #   Amazon S3 can return this if your request involves a bucket that is
    #   either a source or destination in a replication rule.
    #   @return [String]
    #
    # @!attribute [rw] parts_count
    #   The count of parts this object has.
    #   @return [Integer]
    #
    # @!attribute [rw] tag_count
    #   The number of tags, if any, on the object.
    #   @return [Integer]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode currently in place for this object.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when this object's Object Lock will expire.
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Indicates whether this object has an active legal hold. This field
    #   is only returned if you have permission to view an object's legal
    #   hold status.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectOutput AWS API Documentation
    #
    class GetObjectOutput < Struct.new(
      :body,
      :delete_marker,
      :accept_ranges,
      :expiration,
      :restore,
      :last_modified,
      :content_length,
      :etag,
      :missing_meta,
      :version_id,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_range,
      :content_type,
      :expires,
      :expires_string,
      :website_redirect_location,
      :server_side_encryption,
      :metadata,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :storage_class,
      :request_charged,
      :replication_status,
      :parts_count,
      :tag_count,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         if_match: "IfMatch",
    #         if_modified_since: Time.now,
    #         if_none_match: "IfNoneMatch",
    #         if_unmodified_since: Time.now,
    #         key: "ObjectKey", # required
    #         range: "Range",
    #         response_cache_control: "ResponseCacheControl",
    #         response_content_disposition: "ResponseContentDisposition",
    #         response_content_encoding: "ResponseContentEncoding",
    #         response_content_language: "ResponseContentLanguage",
    #         response_content_type: "ResponseContentType",
    #         response_expires: Time.now,
    #         version_id: "ObjectVersionId",
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         request_payer: "requester", # accepts requester
    #         part_number: 1,
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Return the object only if its entity tag (ETag) is the same as the
    #   one specified, otherwise return a 412 (precondition failed).
    #   @return [String]
    #
    # @!attribute [rw] if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time, otherwise return a 304 (not modified).
    #   @return [Time]
    #
    # @!attribute [rw] if_none_match
    #   Return the object only if its entity tag (ETag) is different from
    #   the one specified, otherwise return a 304 (not modified).
    #   @return [String]
    #
    # @!attribute [rw] if_unmodified_since
    #   Return the object only if it has not been modified since the
    #   specified time, otherwise return a 412 (precondition failed).
    #   @return [Time]
    #
    # @!attribute [rw] key
    #   Key of the object to get.
    #   @return [String]
    #
    # @!attribute [rw] range
    #   Downloads the specified range bytes of an object. For more
    #   information about the HTTP Range header, see
    #   [https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35][1].
    #
    #   <note markdown="1"> Amazon S3 doesn't support retrieving multiple ranges of data per
    #   `GET` request.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35
    #   @return [String]
    #
    # @!attribute [rw] response_cache_control
    #   Sets the `Cache-Control` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_disposition
    #   Sets the `Content-Disposition` header of the response
    #   @return [String]
    #
    # @!attribute [rw] response_content_encoding
    #   Sets the `Content-Encoding` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_language
    #   Sets the `Content-Language` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_content_type
    #   Sets the `Content-Type` header of the response.
    #   @return [String]
    #
    # @!attribute [rw] response_expires
    #   Sets the `Expires` header of the response.
    #   @return [Time]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' GET request
    #   for the part specified. Useful for downloading just a part of an
    #   object.
    #   @return [Integer]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRequest AWS API Documentation
    #
    class GetObjectRequest < Struct.new(
      :bucket,
      :if_match,
      :if_modified_since,
      :if_none_match,
      :if_unmodified_since,
      :key,
      :range,
      :response_cache_control,
      :response_content_disposition,
      :response_content_encoding,
      :response_content_language,
      :response_content_type,
      :response_expires,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :part_number,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # @!attribute [rw] retention
    #   The container element for an object's retention settings.
    #   @return [Types::ObjectLockRetention]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRetentionOutput AWS API Documentation
    #
    class GetObjectRetentionOutput < Struct.new(
      :retention)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectRetentionRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object whose retention settings you
    #   want to retrieve.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object whose retention settings you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID for the object whose retention settings you want to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRetentionRequest AWS API Documentation
    #
    class GetObjectRetentionRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object for which you got the tagging
    #   information.
    #   @return [String]
    #
    # @!attribute [rw] tag_set
    #   Contains the tag set.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTaggingOutput AWS API Documentation
    #
    class GetObjectTaggingOutput < Struct.new(
      :version_id,
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object for which to get the tagging
    #   information.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which to get the tagging information.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object for which to get the tagging
    #   information.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTaggingRequest AWS API Documentation
    #
    class GetObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] body
    #   A Bencoded dictionary as defined by the BitTorrent specification
    #   @return [IO]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTorrentOutput AWS API Documentation
    #
    class GetObjectTorrentOutput < Struct.new(
      :body,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetObjectTorrentRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the object for which to get the
    #   torrent files.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key for which to get the information.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTorrentRequest AWS API Documentation
    #
    class GetObjectTorrentRequest < Struct.new(
      :bucket,
      :key,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] public_access_block_configuration
    #   The `PublicAccessBlock` configuration currently in effect for this
    #   Amazon S3 bucket.
    #   @return [Types::PublicAccessBlockConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetPublicAccessBlockOutput AWS API Documentation
    #
    class GetPublicAccessBlockOutput < Struct.new(
      :public_access_block_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetPublicAccessBlockRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to retrieve.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetPublicAccessBlockRequest AWS API Documentation
    #
    class GetPublicAccessBlockRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for S3 Glacier job parameters.
    #
    # @note When making an API call, you may pass GlacierJobParameters
    #   data as a hash:
    #
    #       {
    #         tier: "Standard", # required, accepts Standard, Bulk, Expedited
    #       }
    #
    # @!attribute [rw] tier
    #   S3 Glacier retrieval tier at which the restore will be processed.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GlacierJobParameters AWS API Documentation
    #
    class GlacierJobParameters < Struct.new(
      :tier)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for grant information.
    #
    # @note When making an API call, you may pass Grant
    #   data as a hash:
    #
    #       {
    #         grantee: {
    #           display_name: "DisplayName",
    #           email_address: "EmailAddress",
    #           id: "ID",
    #           type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #           uri: "URI",
    #         },
    #         permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #       }
    #
    # @!attribute [rw] grantee
    #   The person being granted permissions.
    #   @return [Types::Grantee]
    #
    # @!attribute [rw] permission
    #   Specifies the permission given to the grantee.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Grant AWS API Documentation
    #
    class Grant < Struct.new(
      :grantee,
      :permission)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the person being granted permissions.
    #
    # @note When making an API call, you may pass Grantee
    #   data as a hash:
    #
    #       {
    #         display_name: "DisplayName",
    #         email_address: "EmailAddress",
    #         id: "ID",
    #         type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #         uri: "URI",
    #       }
    #
    # @!attribute [rw] display_name
    #   Screen name of the grantee.
    #   @return [String]
    #
    # @!attribute [rw] email_address
    #   Email address of the grantee.
    #
    #   <note markdown="1"> Using email addresses to specify a grantee is only supported in the
    #   following AWS Regions:
    #
    #    * US East (N. Virginia)
    #
    #   * US West (N. California)
    #
    #   * US West (Oregon)
    #
    #   * Asia Pacific (Singapore)
    #
    #   * Asia Pacific (Sydney)
    #
    #   * Asia Pacific (Tokyo)
    #
    #   * Europe (Ireland)
    #
    #   * South America (São Paulo)
    #
    #    For a list of all the Amazon S3 supported Regions and endpoints, see
    #   [Regions and Endpoints][1] in the AWS General Reference.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The canonical user ID of the grantee.
    #   @return [String]
    #
    # @!attribute [rw] type
    #   Type of grantee
    #   @return [String]
    #
    # @!attribute [rw] uri
    #   URI of the grantee group.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Grantee AWS API Documentation
    #
    class Grantee < Struct.new(
      :display_name,
      :email_address,
      :id,
      :type,
      :uri)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass HeadBucketRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadBucketRequest AWS API Documentation
    #
    class HeadBucketRequest < Struct.new(
      :bucket,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] delete_marker
    #   Specifies whether the object retrieved was (true) or was not (false)
    #   a Delete Marker. If false, this response header does not appear in
    #   the response.
    #   @return [Boolean]
    #
    # @!attribute [rw] accept_ranges
    #   Indicates that a range of bytes was specified.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   If the object expiration is configured (see PUT Bucket lifecycle),
    #   the response includes this header. It includes the expiry-date and
    #   rule-id key-value pairs providing object expiration information. The
    #   value of the rule-id is URL encoded.
    #   @return [String]
    #
    # @!attribute [rw] restore
    #   If the object is an archived object (an object whose storage class
    #   is GLACIER), the response includes this header if either the archive
    #   restoration is in progress (see [RestoreObject][1] or an archive
    #   copy is already restored.
    #
    #   If an archive copy is already restored, the header value indicates
    #   when Amazon S3 is scheduled to delete the object copy. For example:
    #
    #   `x-amz-restore: ongoing-request="false", expiry-date="Fri, 23 Dec
    #   2012 00:00:00 GMT"`
    #
    #   If the object restoration is in progress, the header returns the
    #   value `ongoing-request="true"`.
    #
    #   For more information about archiving objects, see [Transitioning
    #   Objects: General Considerations][2].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html#lifecycle-transition-general-considerations
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   Last modified date of the object
    #   @return [Time]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes.
    #   @return [Integer]
    #
    # @!attribute [rw] etag
    #   An ETag is an opaque identifier assigned by a web server to a
    #   specific version of a resource found at a URL.
    #   @return [String]
    #
    # @!attribute [rw] missing_meta
    #   This is set to the number of metadata entries not returned in
    #   `x-amz-meta` headers. This can happen if you create metadata using
    #   an API like SOAP that supports more flexible metadata than the REST
    #   API. For example, using SOAP, you can create metadata whose values
    #   are not legal HTTP headers.
    #   @return [Integer]
    #
    # @!attribute [rw] version_id
    #   Version of the object.
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Specifies caching behavior along the request/reply chain.
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object.
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field.
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the object data.
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable.
    #   @return [Time]
    #
    # @!attribute [rw] expires_string
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   If the object is stored using server-side encryption either with an
    #   AWS KMS customer master key (CMK) or an Amazon S3-managed encryption
    #   key, the response includes this header with the value of the
    #   server-side encryption algorithm used when storing this object in
    #   Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #
    #   For more information, see [Storage Classes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @!attribute [rw] replication_status
    #   Amazon S3 can return this header if your request involves a bucket
    #   that is either a source or destination in a replication rule.
    #
    #   In replication, you have a source bucket on which you configure
    #   replication and destination bucket where Amazon S3 stores object
    #   replicas. When you request an object (`GetObject`) or object
    #   metadata (`HeadObject`) from these buckets, Amazon S3 will return
    #   the `x-amz-replication-status` header in the response as follows:
    #
    #   * If requesting an object from the source bucket — Amazon S3 will
    #     return the `x-amz-replication-status` header if the object in your
    #     request is eligible for replication.
    #
    #     For example, suppose that in your replication configuration, you
    #     specify object prefix `TaxDocs` requesting Amazon S3 to replicate
    #     objects with key prefix `TaxDocs`. Any objects you upload with
    #     this key name prefix, for example `TaxDocs/document1.pdf`, are
    #     eligible for replication. For any object request with this key
    #     name prefix, Amazon S3 will return the `x-amz-replication-status`
    #     header with value PENDING, COMPLETED or FAILED indicating object
    #     replication status.
    #
    #   * If requesting an object from the destination bucket — Amazon S3
    #     will return the `x-amz-replication-status` header with value
    #     REPLICA if the object in your request is a replica that Amazon S3
    #     created.
    #
    #   For more information, see [Replication][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [String]
    #
    # @!attribute [rw] parts_count
    #   The count of parts this object has.
    #   @return [Integer]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode, if any, that's in effect for this object.
    #   This header is only returned if the requester has the
    #   `s3:GetObjectRetention` permission. For more information about S3
    #   Object Lock, see [Object Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when the Object Lock retention period expires.
    #   This header is only returned if the requester has the
    #   `s3:GetObjectRetention` permission.
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether a legal hold is in effect for this object. This
    #   header is only returned if the requester has the
    #   `s3:GetObjectLegalHold` permission. This header is not returned if
    #   the specified version of this object has never had a legal hold
    #   applied. For more information about S3 Object Lock, see [Object
    #   Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadObjectOutput AWS API Documentation
    #
    class HeadObjectOutput < Struct.new(
      :delete_marker,
      :accept_ranges,
      :expiration,
      :restore,
      :last_modified,
      :content_length,
      :etag,
      :missing_meta,
      :version_id,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_type,
      :expires,
      :expires_string,
      :website_redirect_location,
      :server_side_encryption,
      :metadata,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :storage_class,
      :request_charged,
      :replication_status,
      :parts_count,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @note When making an API call, you may pass HeadObjectRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         if_match: "IfMatch",
    #         if_modified_since: Time.now,
    #         if_none_match: "IfNoneMatch",
    #         if_unmodified_since: Time.now,
    #         key: "ObjectKey", # required
    #         range: "Range",
    #         version_id: "ObjectVersionId",
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         request_payer: "requester", # accepts requester
    #         part_number: 1,
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the object.
    #   @return [String]
    #
    # @!attribute [rw] if_match
    #   Return the object only if its entity tag (ETag) is the same as the
    #   one specified, otherwise return a 412 (precondition failed).
    #   @return [String]
    #
    # @!attribute [rw] if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time, otherwise return a 304 (not modified).
    #   @return [Time]
    #
    # @!attribute [rw] if_none_match
    #   Return the object only if its entity tag (ETag) is different from
    #   the one specified, otherwise return a 304 (not modified).
    #   @return [String]
    #
    # @!attribute [rw] if_unmodified_since
    #   Return the object only if it has not been modified since the
    #   specified time, otherwise return a 412 (precondition failed).
    #   @return [Time]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] range
    #   Downloads the specified range bytes of an object. For more
    #   information about the HTTP Range header, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35]().
    #
    #   <note markdown="1"> Amazon S3 doesn't support retrieving multiple ranges of data per
    #   `GET` request.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' HEAD request
    #   for the part specified. Useful querying about the size of the part
    #   and the number of parts in this object.
    #   @return [Integer]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadObjectRequest AWS API Documentation
    #
    class HeadObjectRequest < Struct.new(
      :bucket,
      :if_match,
      :if_modified_since,
      :if_none_match,
      :if_unmodified_since,
      :key,
      :range,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :part_number,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Container for the `Suffix` element.
    #
    # @note When making an API call, you may pass IndexDocument
    #   data as a hash:
    #
    #       {
    #         suffix: "Suffix", # required
    #       }
    #
    # @!attribute [rw] suffix
    #   A suffix that is appended to a request that is for a directory on
    #   the website endpoint (for example,if the suffix is index.html and
    #   you make a request to samplebucket/images/ the data that is returned
    #   will be for the object with the key name images/index.html) The
    #   suffix must not be empty and must not include a slash character.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/IndexDocument AWS API Documentation
    #
    class IndexDocument < Struct.new(
      :suffix)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container element that identifies who initiated the multipart upload.
    #
    # @!attribute [rw] id
    #   If the principal is an AWS account, it provides the Canonical User
    #   ID. If the principal is an IAM User, it provides a user ARN value.
    #   @return [String]
    #
    # @!attribute [rw] display_name
    #   Name of the Principal.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Initiator AWS API Documentation
    #
    class Initiator < Struct.new(
      :id,
      :display_name)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the serialization format of the object.
    #
    # @note When making an API call, you may pass InputSerialization
    #   data as a hash:
    #
    #       {
    #         csv: {
    #           file_header_info: "USE", # accepts USE, IGNORE, NONE
    #           comments: "Comments",
    #           quote_escape_character: "QuoteEscapeCharacter",
    #           record_delimiter: "RecordDelimiter",
    #           field_delimiter: "FieldDelimiter",
    #           quote_character: "QuoteCharacter",
    #           allow_quoted_record_delimiter: false,
    #         },
    #         compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #         json: {
    #           type: "DOCUMENT", # accepts DOCUMENT, LINES
    #         },
    #         parquet: {
    #         },
    #       }
    #
    # @!attribute [rw] csv
    #   Describes the serialization of a CSV-encoded object.
    #   @return [Types::CSVInput]
    #
    # @!attribute [rw] compression_type
    #   Specifies object's compression format. Valid values: NONE, GZIP,
    #   BZIP2. Default Value: NONE.
    #   @return [String]
    #
    # @!attribute [rw] json
    #   Specifies JSON as object's input serialization format.
    #   @return [Types::JSONInput]
    #
    # @!attribute [rw] parquet
    #   Specifies Parquet as object's input serialization format.
    #   @return [Types::ParquetInput]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InputSerialization AWS API Documentation
    #
    class InputSerialization < Struct.new(
      :csv,
      :compression_type,
      :json,
      :parquet)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the inventory configuration for an Amazon S3 bucket. For
    # more information, see [GET Bucket inventory][1] in the *Amazon Simple
    # Storage Service API Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETInventoryConfig.html
    #
    # @note When making an API call, you may pass InventoryConfiguration
    #   data as a hash:
    #
    #       {
    #         destination: { # required
    #           s3_bucket_destination: { # required
    #             account_id: "AccountId",
    #             bucket: "BucketName", # required
    #             format: "CSV", # required, accepts CSV, ORC, Parquet
    #             prefix: "Prefix",
    #             encryption: {
    #               sses3: {
    #               },
    #               ssekms: {
    #                 key_id: "SSEKMSKeyId", # required
    #               },
    #             },
    #           },
    #         },
    #         is_enabled: false, # required
    #         filter: {
    #           prefix: "Prefix", # required
    #         },
    #         id: "InventoryId", # required
    #         included_object_versions: "All", # required, accepts All, Current
    #         optional_fields: ["Size"], # accepts Size, LastModifiedDate, StorageClass, ETag, IsMultipartUploaded, ReplicationStatus, EncryptionStatus, ObjectLockRetainUntilDate, ObjectLockMode, ObjectLockLegalHoldStatus, IntelligentTieringAccessTier
    #         schedule: { # required
    #           frequency: "Daily", # required, accepts Daily, Weekly
    #         },
    #       }
    #
    # @!attribute [rw] destination
    #   Contains information about where to publish the inventory results.
    #   @return [Types::InventoryDestination]
    #
    # @!attribute [rw] is_enabled
    #   Specifies whether the inventory is enabled or disabled. If set to
    #   `True`, an inventory list is generated. If set to `False`, no
    #   inventory list is generated.
    #   @return [Boolean]
    #
    # @!attribute [rw] filter
    #   Specifies an inventory filter. The inventory only includes objects
    #   that meet the filter's criteria.
    #   @return [Types::InventoryFilter]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] included_object_versions
    #   Object versions to include in the inventory list. If set to `All`,
    #   the list includes all the object versions, which adds the
    #   version-related fields `VersionId`, `IsLatest`, and `DeleteMarker`
    #   to the list. If set to `Current`, the list does not contain these
    #   version-related fields.
    #   @return [String]
    #
    # @!attribute [rw] optional_fields
    #   Contains the optional fields that are included in the inventory
    #   results.
    #   @return [Array<String>]
    #
    # @!attribute [rw] schedule
    #   Specifies the schedule for generating inventory results.
    #   @return [Types::InventorySchedule]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryConfiguration AWS API Documentation
    #
    class InventoryConfiguration < Struct.new(
      :destination,
      :is_enabled,
      :filter,
      :id,
      :included_object_versions,
      :optional_fields,
      :schedule)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the inventory configuration for an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass InventoryDestination
    #   data as a hash:
    #
    #       {
    #         s3_bucket_destination: { # required
    #           account_id: "AccountId",
    #           bucket: "BucketName", # required
    #           format: "CSV", # required, accepts CSV, ORC, Parquet
    #           prefix: "Prefix",
    #           encryption: {
    #             sses3: {
    #             },
    #             ssekms: {
    #               key_id: "SSEKMSKeyId", # required
    #             },
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] s3_bucket_destination
    #   Contains the bucket name, file format, bucket owner (optional), and
    #   prefix (optional) where inventory results are published.
    #   @return [Types::InventoryS3BucketDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryDestination AWS API Documentation
    #
    class InventoryDestination < Struct.new(
      :s3_bucket_destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the type of server-side encryption used to encrypt the
    # inventory results.
    #
    # @note When making an API call, you may pass InventoryEncryption
    #   data as a hash:
    #
    #       {
    #         sses3: {
    #         },
    #         ssekms: {
    #           key_id: "SSEKMSKeyId", # required
    #         },
    #       }
    #
    # @!attribute [rw] sses3
    #   Specifies the use of SSE-S3 to encrypt delivered inventory reports.
    #   @return [Types::SSES3]
    #
    # @!attribute [rw] ssekms
    #   Specifies the use of SSE-KMS to encrypt delivered inventory reports.
    #   @return [Types::SSEKMS]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryEncryption AWS API Documentation
    #
    class InventoryEncryption < Struct.new(
      :sses3,
      :ssekms)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies an inventory filter. The inventory only includes objects
    # that meet the filter's criteria.
    #
    # @note When making an API call, you may pass InventoryFilter
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix", # required
    #       }
    #
    # @!attribute [rw] prefix
    #   The prefix that an object must have to be included in the inventory
    #   results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryFilter AWS API Documentation
    #
    class InventoryFilter < Struct.new(
      :prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the bucket name, file format, bucket owner (optional), and
    # prefix (optional) where inventory results are published.
    #
    # @note When making an API call, you may pass InventoryS3BucketDestination
    #   data as a hash:
    #
    #       {
    #         account_id: "AccountId",
    #         bucket: "BucketName", # required
    #         format: "CSV", # required, accepts CSV, ORC, Parquet
    #         prefix: "Prefix",
    #         encryption: {
    #           sses3: {
    #           },
    #           ssekms: {
    #             key_id: "SSEKMSKeyId", # required
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] account_id
    #   The account ID that owns the destination S3 bucket. If no account ID
    #   is provided, the owner is not validated before exporting data.
    #
    #   <note markdown="1"> Although this value is optional, we strongly recommend that you set
    #   it to help prevent problems if the destination bucket ownership
    #   changes.
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   The Amazon Resource Name (ARN) of the bucket where inventory results
    #   will be published.
    #   @return [String]
    #
    # @!attribute [rw] format
    #   Specifies the output format of the inventory results.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix that is prepended to all inventory results.
    #   @return [String]
    #
    # @!attribute [rw] encryption
    #   Contains the type of server-side encryption used to encrypt the
    #   inventory results.
    #   @return [Types::InventoryEncryption]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventoryS3BucketDestination AWS API Documentation
    #
    class InventoryS3BucketDestination < Struct.new(
      :account_id,
      :bucket,
      :format,
      :prefix,
      :encryption)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the schedule for generating inventory results.
    #
    # @note When making an API call, you may pass InventorySchedule
    #   data as a hash:
    #
    #       {
    #         frequency: "Daily", # required, accepts Daily, Weekly
    #       }
    #
    # @!attribute [rw] frequency
    #   Specifies how frequently inventory results are produced.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/InventorySchedule AWS API Documentation
    #
    class InventorySchedule < Struct.new(
      :frequency)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies JSON as object's input serialization format.
    #
    # @note When making an API call, you may pass JSONInput
    #   data as a hash:
    #
    #       {
    #         type: "DOCUMENT", # accepts DOCUMENT, LINES
    #       }
    #
    # @!attribute [rw] type
    #   The type of JSON. Valid values: Document, Lines.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JSONInput AWS API Documentation
    #
    class JSONInput < Struct.new(
      :type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies JSON as request's output serialization format.
    #
    # @note When making an API call, you may pass JSONOutput
    #   data as a hash:
    #
    #       {
    #         record_delimiter: "RecordDelimiter",
    #       }
    #
    # @!attribute [rw] record_delimiter
    #   The value used to separate individual records in the output. If no
    #   value is specified, Amazon S3 uses a newline character ('\\n').
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/JSONOutput AWS API Documentation
    #
    class JSONOutput < Struct.new(
      :record_delimiter)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for AWS Lambda
    # notifications.
    #
    # @note When making an API call, you may pass LambdaFunctionConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         lambda_function_arn: "LambdaFunctionArn", # required
    #         events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         filter: {
    #           key: {
    #             filter_rules: [
    #               {
    #                 name: "prefix", # accepts prefix, suffix
    #                 value: "FilterRuleValue",
    #               },
    #             ],
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] lambda_function_arn
    #   The Amazon Resource Name (ARN) of the AWS Lambda function that
    #   Amazon S3 invokes when the specified event type occurs.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   The Amazon S3 bucket event for which to invoke the AWS Lambda
    #   function. For more information, see [Supported Event Types][1] in
    #   the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring Event Notifications][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LambdaFunctionConfiguration AWS API Documentation
    #
    class LambdaFunctionConfiguration < Struct.new(
      :id,
      :lambda_function_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for lifecycle rules. You can add as many as 1000 rules.
    #
    # @note When making an API call, you may pass LifecycleConfiguration
    #   data as a hash:
    #
    #       {
    #         rules: [ # required
    #           {
    #             expiration: {
    #               date: Time.now,
    #               days: 1,
    #               expired_object_delete_marker: false,
    #             },
    #             id: "ID",
    #             prefix: "Prefix", # required
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #             transition: {
    #               date: Time.now,
    #               days: 1,
    #               storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #             },
    #             noncurrent_version_transition: {
    #               noncurrent_days: 1,
    #               storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #             },
    #             noncurrent_version_expiration: {
    #               noncurrent_days: 1,
    #             },
    #             abort_incomplete_multipart_upload: {
    #               days_after_initiation: 1,
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] rules
    #   Specifies lifecycle configuration rules for an Amazon S3 bucket.
    #   @return [Array<Types::Rule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleConfiguration AWS API Documentation
    #
    class LifecycleConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the expiration for the lifecycle of the object.
    #
    # @note When making an API call, you may pass LifecycleExpiration
    #   data as a hash:
    #
    #       {
    #         date: Time.now,
    #         days: 1,
    #         expired_object_delete_marker: false,
    #       }
    #
    # @!attribute [rw] date
    #   Indicates at what date the object is to be moved or deleted. Should
    #   be in GMT ISO 8601 Format.
    #   @return [Time]
    #
    # @!attribute [rw] days
    #   Indicates the lifetime, in days, of the objects that are subject to
    #   the rule. The value must be a non-zero positive integer.
    #   @return [Integer]
    #
    # @!attribute [rw] expired_object_delete_marker
    #   Indicates whether Amazon S3 will remove a delete marker with no
    #   noncurrent versions. If set to true, the delete marker will be
    #   expired; if set to false the policy takes no action. This cannot be
    #   specified with Days or Date in a Lifecycle Expiration Policy.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleExpiration AWS API Documentation
    #
    class LifecycleExpiration < Struct.new(
      :date,
      :days,
      :expired_object_delete_marker)
      SENSITIVE = []
      include Aws::Structure
    end

    # A lifecycle rule for individual objects in an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass LifecycleRule
    #   data as a hash:
    #
    #       {
    #         expiration: {
    #           date: Time.now,
    #           days: 1,
    #           expired_object_delete_marker: false,
    #         },
    #         id: "ID",
    #         prefix: "Prefix",
    #         filter: {
    #           prefix: "Prefix",
    #           tag: {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #           and: {
    #             prefix: "Prefix",
    #             tags: [
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #         },
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #         transitions: [
    #           {
    #             date: Time.now,
    #             days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #           },
    #         ],
    #         noncurrent_version_transitions: [
    #           {
    #             noncurrent_days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #           },
    #         ],
    #         noncurrent_version_expiration: {
    #           noncurrent_days: 1,
    #         },
    #         abort_incomplete_multipart_upload: {
    #           days_after_initiation: 1,
    #         },
    #       }
    #
    # @!attribute [rw] expiration
    #   Specifies the expiration for the lifecycle of the object in the form
    #   of date, days and, whether the object has a delete marker.
    #   @return [Types::LifecycleExpiration]
    #
    # @!attribute [rw] id
    #   Unique identifier for the rule. The value cannot be longer than 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Prefix identifying one or more objects to which the rule applies.
    #   This is No longer used; use `Filter` instead.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   The `Filter` is used to identify objects that a Lifecycle Rule
    #   applies to. A `Filter` must have exactly one of `Prefix`, `Tag`, or
    #   `And` specified.
    #   @return [Types::LifecycleRuleFilter]
    #
    # @!attribute [rw] status
    #   If 'Enabled', the rule is currently being applied. If
    #   'Disabled', the rule is not currently being applied.
    #   @return [String]
    #
    # @!attribute [rw] transitions
    #   Specifies when an Amazon S3 object transitions to a specified
    #   storage class.
    #   @return [Array<Types::Transition>]
    #
    # @!attribute [rw] noncurrent_version_transitions
    #   Specifies the transition rule for the lifecycle rule that describes
    #   when noncurrent objects transition to a specific storage class. If
    #   your bucket is versioning-enabled (or versioning is suspended), you
    #   can set this action to request that Amazon S3 transition noncurrent
    #   object versions to a specific storage class at a set period in the
    #   object's lifetime.
    #   @return [Array<Types::NoncurrentVersionTransition>]
    #
    # @!attribute [rw] noncurrent_version_expiration
    #   Specifies when noncurrent object versions expire. Upon expiration,
    #   Amazon S3 permanently deletes the noncurrent object versions. You
    #   set this lifecycle configuration action on a bucket that has
    #   versioning enabled (or suspended) to request that Amazon S3 delete
    #   noncurrent object versions at a specific period in the object's
    #   lifetime.
    #   @return [Types::NoncurrentVersionExpiration]
    #
    # @!attribute [rw] abort_incomplete_multipart_upload
    #   Specifies the days since the initiation of an incomplete multipart
    #   upload that Amazon S3 will wait before permanently removing all
    #   parts of the upload. For more information, see [ Aborting Incomplete
    #   Multipart Uploads Using a Bucket Lifecycle Policy][1] in the *Amazon
    #   Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Types::AbortIncompleteMultipartUpload]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRule AWS API Documentation
    #
    class LifecycleRule < Struct.new(
      :expiration,
      :id,
      :prefix,
      :filter,
      :status,
      :transitions,
      :noncurrent_version_transitions,
      :noncurrent_version_expiration,
      :abort_incomplete_multipart_upload)
      SENSITIVE = []
      include Aws::Structure
    end

    # This is used in a Lifecycle Rule Filter to apply a logical AND to two
    # or more predicates. The Lifecycle Rule will apply to any object
    # matching all of the predicates configured inside the And operator.
    #
    # @note When making an API call, you may pass LifecycleRuleAndOperator
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tags: [
    #           {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] prefix
    #   Prefix identifying one or more objects to which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   All of these tags must exist in the object's tag set in order for
    #   the rule to apply.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRuleAndOperator AWS API Documentation
    #
    class LifecycleRuleAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # The `Filter` is used to identify objects that a Lifecycle Rule applies
    # to. A `Filter` must have exactly one of `Prefix`, `Tag`, or `And`
    # specified.
    #
    # @note When making an API call, you may pass LifecycleRuleFilter
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       }
    #
    # @!attribute [rw] prefix
    #   Prefix identifying one or more objects to which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   This tag must exist in the object's tag set in order for the rule
    #   to apply.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   This is used in a Lifecycle Rule Filter to apply a logical AND to
    #   two or more predicates. The Lifecycle Rule will apply to any object
    #   matching all of the predicates configured inside the And operator.
    #   @return [Types::LifecycleRuleAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LifecycleRuleFilter AWS API Documentation
    #
    class LifecycleRuleFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of analytics configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken will be provided for a subsequent
    #   request.
    #   @return [Boolean]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used as a starting point for this analytics
    #   configuration list response. This value is present if it was sent in
    #   the request.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   `NextContinuationToken` is sent when `isTruncated` is true, which
    #   indicates that there are more analytics configurations to list. The
    #   next request must include this `NextContinuationToken`. The token is
    #   obfuscated and is not a usable value.
    #   @return [String]
    #
    # @!attribute [rw] analytics_configuration_list
    #   The list of analytics configurations for a bucket.
    #   @return [Array<Types::AnalyticsConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketAnalyticsConfigurationsOutput AWS API Documentation
    #
    class ListBucketAnalyticsConfigurationsOutput < Struct.new(
      :is_truncated,
      :continuation_token,
      :next_continuation_token,
      :analytics_configuration_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListBucketAnalyticsConfigurationsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         continuation_token: "Token",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket from which analytics configurations are
    #   retrieved.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The ContinuationToken that represents a placeholder from where this
    #   request should begin.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketAnalyticsConfigurationsRequest AWS API Documentation
    #
    class ListBucketAnalyticsConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] continuation_token
    #   If sent in the request, the marker that is used as a starting point
    #   for this inventory configuration list response.
    #   @return [String]
    #
    # @!attribute [rw] inventory_configuration_list
    #   The list of inventory configurations for a bucket.
    #   @return [Array<Types::InventoryConfiguration>]
    #
    # @!attribute [rw] is_truncated
    #   Tells whether the returned list of inventory configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken is provided for a subsequent request.
    #   @return [Boolean]
    #
    # @!attribute [rw] next_continuation_token
    #   The marker used to continue this inventory configuration listing.
    #   Use the `NextContinuationToken` from this response to continue the
    #   listing in a subsequent request. The continuation token is an opaque
    #   value that Amazon S3 understands.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketInventoryConfigurationsOutput AWS API Documentation
    #
    class ListBucketInventoryConfigurationsOutput < Struct.new(
      :continuation_token,
      :inventory_configuration_list,
      :is_truncated,
      :next_continuation_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListBucketInventoryConfigurationsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         continuation_token: "Token",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the inventory configurations to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The marker used to continue an inventory configuration listing that
    #   has been truncated. Use the NextContinuationToken from a previously
    #   truncated list response to continue the listing. The continuation
    #   token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketInventoryConfigurationsRequest AWS API Documentation
    #
    class ListBucketInventoryConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of metrics configurations is
    #   complete. A value of true indicates that the list is not complete
    #   and the NextContinuationToken will be provided for a subsequent
    #   request.
    #   @return [Boolean]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used as a starting point for this metrics
    #   configuration list response. This value is present if it was sent in
    #   the request.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   The marker used to continue a metrics configuration listing that has
    #   been truncated. Use the `NextContinuationToken` from a previously
    #   truncated list response to continue the listing. The continuation
    #   token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] metrics_configuration_list
    #   The list of metrics configurations for a bucket.
    #   @return [Array<Types::MetricsConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketMetricsConfigurationsOutput AWS API Documentation
    #
    class ListBucketMetricsConfigurationsOutput < Struct.new(
      :is_truncated,
      :continuation_token,
      :next_continuation_token,
      :metrics_configuration_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListBucketMetricsConfigurationsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         continuation_token: "Token",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the metrics configurations to
    #   retrieve.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   The marker that is used to continue a metrics configuration listing
    #   that has been truncated. Use the NextContinuationToken from a
    #   previously truncated list response to continue the listing. The
    #   continuation token is an opaque value that Amazon S3 understands.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketMetricsConfigurationsRequest AWS API Documentation
    #
    class ListBucketMetricsConfigurationsRequest < Struct.new(
      :bucket,
      :continuation_token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] buckets
    #   The list of buckets owned by the requestor.
    #   @return [Array<Types::Bucket>]
    #
    # @!attribute [rw] owner
    #   The owner of the buckets listed.
    #   @return [Types::Owner]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketsOutput AWS API Documentation
    #
    class ListBucketsOutput < Struct.new(
      :buckets,
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   The key at or after which the listing began.
    #   @return [String]
    #
    # @!attribute [rw] upload_id_marker
    #   Upload ID after which listing began.
    #   @return [String]
    #
    # @!attribute [rw] next_key_marker
    #   When a list is truncated, this element specifies the value that
    #   should be used for the key-marker request parameter in a subsequent
    #   request.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   When a prefix is provided in the request, this field contains the
    #   specified prefix. The result contains only keys starting with the
    #   specified prefix.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Contains the delimiter you specified in the request. If you don't
    #   specify a delimiter in your request, this element is absent from the
    #   response.
    #   @return [String]
    #
    # @!attribute [rw] next_upload_id_marker
    #   When a list is truncated, this element specifies the value that
    #   should be used for the `upload-id-marker` request parameter in a
    #   subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] max_uploads
    #   Maximum number of multipart uploads that could have been included in
    #   the response.
    #   @return [Integer]
    #
    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of multipart uploads is
    #   truncated. A value of true indicates that the list was truncated.
    #   The list can be truncated if the number of multipart uploads exceeds
    #   the limit allowed or specified by max uploads.
    #   @return [Boolean]
    #
    # @!attribute [rw] uploads
    #   Container for elements related to a particular multipart upload. A
    #   response can contain zero or more `Upload` elements.
    #   @return [Array<Types::MultipartUpload>]
    #
    # @!attribute [rw] common_prefixes
    #   If you specify a delimiter in the request, then the result returns
    #   each distinct key prefix containing the delimiter in a
    #   `CommonPrefixes` element. The distinct key prefixes are returned in
    #   the `Prefix` child element.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object keys in the
    #   response.
    #
    #   If you specify `encoding-type` request parameter, Amazon S3 includes
    #   this element in the response, and returns encoded key name values in
    #   the following response elements:
    #
    #   `Delimiter`, `KeyMarker`, `Prefix`, `NextKeyMarker`, `Key`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListMultipartUploadsOutput AWS API Documentation
    #
    class ListMultipartUploadsOutput < Struct.new(
      :bucket,
      :key_marker,
      :upload_id_marker,
      :next_key_marker,
      :prefix,
      :delimiter,
      :next_upload_id_marker,
      :max_uploads,
      :is_truncated,
      :uploads,
      :common_prefixes,
      :encoding_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListMultipartUploadsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         delimiter: "Delimiter",
    #         encoding_type: "url", # accepts url
    #         key_marker: "KeyMarker",
    #         max_uploads: 1,
    #         prefix: "Prefix",
    #         upload_id_marker: "UploadIdMarker",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Character you use to group keys.
    #
    #   All keys that contain the same string between the prefix, if
    #   specified, and the first occurrence of the delimiter after the
    #   prefix are grouped under a single result element, `CommonPrefixes`.
    #   If you don't specify the prefix parameter, then the substring
    #   starts at the beginning of the key. The keys that are grouped under
    #   `CommonPrefixes` result element are not returned elsewhere in the
    #   response.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   Together with upload-id-marker, this parameter specifies the
    #   multipart upload after which listing should begin.
    #
    #   If `upload-id-marker` is not specified, only the keys
    #   lexicographically greater than the specified `key-marker` will be
    #   included in the list.
    #
    #   If `upload-id-marker` is specified, any multipart uploads for a key
    #   equal to the `key-marker` might also be included, provided those
    #   multipart uploads have upload IDs lexicographically greater than the
    #   specified `upload-id-marker`.
    #   @return [String]
    #
    # @!attribute [rw] max_uploads
    #   Sets the maximum number of multipart uploads, from 1 to 1,000, to
    #   return in the response body. 1,000 is the maximum number of uploads
    #   that can be returned in a response.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Lists in-progress uploads only for those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different grouping of keys. (You can think of using prefix to make
    #   groups in the same way you'd use a folder in a file system.)
    #   @return [String]
    #
    # @!attribute [rw] upload_id_marker
    #   Together with key-marker, specifies the multipart upload after which
    #   listing should begin. If key-marker is not specified, the
    #   upload-id-marker parameter is ignored. Otherwise, any multipart
    #   uploads for a key equal to the key-marker might be included in the
    #   list only if they have an upload ID lexicographically greater than
    #   the specified `upload-id-marker`.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListMultipartUploadsRequest AWS API Documentation
    #
    class ListMultipartUploadsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :key_marker,
      :max_uploads,
      :prefix,
      :upload_id_marker,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   A flag that indicates whether Amazon S3 returned all of the results
    #   that satisfied the search criteria. If your results were truncated,
    #   you can make a follow-up paginated request using the NextKeyMarker
    #   and NextVersionIdMarker response parameters as a starting place in
    #   another request to return the rest of the results.
    #   @return [Boolean]
    #
    # @!attribute [rw] key_marker
    #   Marks the last key returned in a truncated response.
    #   @return [String]
    #
    # @!attribute [rw] version_id_marker
    #   Marks the last version of the key returned in a truncated response.
    #   @return [String]
    #
    # @!attribute [rw] next_key_marker
    #   When the number of responses exceeds the value of `MaxKeys`,
    #   `NextKeyMarker` specifies the first key not returned that satisfies
    #   the search criteria. Use this value for the key-marker request
    #   parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] next_version_id_marker
    #   When the number of responses exceeds the value of `MaxKeys`,
    #   `NextVersionIdMarker` specifies the first object version not
    #   returned that satisfies the search criteria. Use this value for the
    #   version-id-marker request parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] versions
    #   Container for version information.
    #   @return [Array<Types::ObjectVersion>]
    #
    # @!attribute [rw] delete_markers
    #   Container for an object that is a delete marker.
    #   @return [Array<Types::DeleteMarkerEntry>]
    #
    # @!attribute [rw] name
    #   Bucket name.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Selects objects that start with the value supplied by this
    #   parameter.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   The delimiter grouping the included keys. A delimiter is a character
    #   that you specify to group keys. All keys that contain the same
    #   string between the prefix and the first occurrence of the delimiter
    #   are grouped under a single result element in `CommonPrefixes`. These
    #   groups are counted as one result against the max-keys limitation.
    #   These keys are not returned elsewhere in the response.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Specifies the maximum number of objects to return.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys rolled up into a common prefix count as a single
    #   return when calculating the number of returns.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object key names in the
    #   XML response.
    #
    #   If you specify encoding-type request parameter, Amazon S3 includes
    #   this element in the response, and returns encoded key name values in
    #   the following response elements:
    #
    #   `KeyMarker, NextKeyMarker, Prefix, Key`, and `Delimiter`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectVersionsOutput AWS API Documentation
    #
    class ListObjectVersionsOutput < Struct.new(
      :is_truncated,
      :key_marker,
      :version_id_marker,
      :next_key_marker,
      :next_version_id_marker,
      :versions,
      :delete_markers,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListObjectVersionsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         delimiter: "Delimiter",
    #         encoding_type: "url", # accepts url
    #         key_marker: "KeyMarker",
    #         max_keys: 1,
    #         prefix: "Prefix",
    #         version_id_marker: "VersionIdMarker",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name that contains the objects.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character that you specify to group keys. All keys
    #   that contain the same string between the `prefix` and the first
    #   occurrence of the delimiter are grouped under a single result
    #   element in CommonPrefixes. These groups are counted as one result
    #   against the max-keys limitation. These keys are not returned
    #   elsewhere in the response.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #   @return [String]
    #
    # @!attribute [rw] key_marker
    #   Specifies the key to start with when listing objects in a bucket.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the API returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more. If additional keys satisfy
    #   the search criteria, but were not returned because max-keys was
    #   exceeded, the response contains
    #   &lt;isTruncated&gt;true&lt;/isTruncated&gt;. To return the
    #   additional keys, see key-marker and version-id-marker.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Use this parameter to select only those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different groupings of keys. (You can think of using prefix to make
    #   groups in the same way you'd use a folder in a file system.) You
    #   can use prefix with delimiter to roll up numerous objects into a
    #   single result under CommonPrefixes.
    #   @return [String]
    #
    # @!attribute [rw] version_id_marker
    #   Specifies the object version you want to start listing from.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectVersionsRequest AWS API Documentation
    #
    class ListObjectVersionsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :key_marker,
      :max_keys,
      :prefix,
      :version_id_marker,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   A flag that indicates whether Amazon S3 returned all of the results
    #   that satisfied the search criteria.
    #   @return [Boolean]
    #
    # @!attribute [rw] marker
    #   Indicates where in the bucket listing begins. Marker is included in
    #   the response if it was sent with the request.
    #   @return [String]
    #
    # @!attribute [rw] next_marker
    #   When response is truncated (the IsTruncated element value in the
    #   response is true), you can use the key name in this field as marker
    #   in the subsequent request to get next set of objects. Amazon S3
    #   lists objects in alphabetical order Note: This element is returned
    #   only if you have delimiter request parameter specified. If response
    #   does not include the NextMarker and it is truncated, you can use the
    #   value of the last Key in the response as the marker in the
    #   subsequent request to get the next set of object keys.
    #   @return [String]
    #
    # @!attribute [rw] contents
    #   Metadata about each object returned.
    #   @return [Array<Types::Object>]
    #
    # @!attribute [rw] name
    #   Bucket name.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Keys that begin with the indicated prefix.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Causes keys that contain the same string between the prefix and the
    #   first occurrence of the delimiter to be rolled up into a single
    #   result element in the `CommonPrefixes` collection. These rolled-up
    #   keys are not returned elsewhere in the response. Each rolled-up
    #   result counts as only one return against the `MaxKeys` value.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   The maximum number of keys returned in the response body.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys rolled up in a common prefix count as a single
    #   return when calculating the number of returns.
    #
    #   A response can contain CommonPrefixes only if you specify a
    #   delimiter.
    #
    #   CommonPrefixes contains all (if there are any) keys between Prefix
    #   and the next occurrence of the string specified by the delimiter.
    #
    #   CommonPrefixes lists keys that act like subdirectories in the
    #   directory specified by Prefix.
    #
    #   For example, if the prefix is notes/ and the delimiter is a slash
    #   (/) as in notes/summer/july, the common prefix is notes/summer/. All
    #   of the keys that roll up into a common prefix count as a single
    #   return when calculating the number of returns.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object keys in the
    #   response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsOutput AWS API Documentation
    #
    class ListObjectsOutput < Struct.new(
      :is_truncated,
      :marker,
      :next_marker,
      :contents,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListObjectsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         delimiter: "Delimiter",
    #         encoding_type: "url", # accepts url
    #         marker: "Marker",
    #         max_keys: 1,
    #         prefix: "Prefix",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket containing the objects.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character you use to group keys.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #   @return [String]
    #
    # @!attribute [rw] marker
    #   Specifies the key to start with when listing objects in a bucket.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the API returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Limits the response to keys that begin with the specified prefix.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request. Bucket owners need not specify this
    #   parameter in their requests.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsRequest AWS API Documentation
    #
    class ListObjectsRequest < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :marker,
      :max_keys,
      :prefix,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] is_truncated
    #   Set to false if all of the results were returned. Set to true if
    #   more keys are available to return. If the number of results exceeds
    #   that specified by MaxKeys, all of the results might not be returned.
    #   @return [Boolean]
    #
    # @!attribute [rw] contents
    #   Metadata about each object returned.
    #   @return [Array<Types::Object>]
    #
    # @!attribute [rw] name
    #   Bucket name.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Keys that begin with the indicated prefix.
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   Causes keys that contain the same string between the prefix and the
    #   first occurrence of the delimiter to be rolled up into a single
    #   result element in the CommonPrefixes collection. These rolled-up
    #   keys are not returned elsewhere in the response. Each rolled-up
    #   result counts as only one return against the `MaxKeys` value.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the API returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] common_prefixes
    #   All of the keys rolled up into a common prefix count as a single
    #   return when calculating the number of returns.
    #
    #   A response can contain `CommonPrefixes` only if you specify a
    #   delimiter.
    #
    #   `CommonPrefixes` contains all (if there are any) keys between
    #   `Prefix` and the next occurrence of the string specified by a
    #   delimiter.
    #
    #   `CommonPrefixes` lists keys that act like subdirectories in the
    #   directory specified by `Prefix`.
    #
    #   For example, if the prefix is `notes/` and the delimiter is a slash
    #   (`/`) as in `notes/summer/july`, the common prefix is
    #   `notes/summer/`. All of the keys that roll up into a common prefix
    #   count as a single return when calculating the number of returns.
    #   @return [Array<Types::CommonPrefix>]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object key names in the
    #   XML response.
    #
    #   If you specify the encoding-type request parameter, Amazon S3
    #   includes this element in the response, and returns encoded key name
    #   values in the following response elements:
    #
    #   `Delimiter, Prefix, Key,` and `StartAfter`.
    #   @return [String]
    #
    # @!attribute [rw] key_count
    #   KeyCount is the number of keys returned with this request. KeyCount
    #   will always be less than equals to MaxKeys field. Say you ask for 50
    #   keys, your result will include less than equals 50 keys
    #   @return [Integer]
    #
    # @!attribute [rw] continuation_token
    #   If ContinuationToken was sent with the request, it is included in
    #   the response.
    #   @return [String]
    #
    # @!attribute [rw] next_continuation_token
    #   `NextContinuationToken` is sent when `isTruncated` is true, which
    #   means there are more keys in the bucket that can be listed. The next
    #   list requests to Amazon S3 can be continued with this
    #   `NextContinuationToken`. `NextContinuationToken` is obfuscated and
    #   is not a real key
    #   @return [String]
    #
    # @!attribute [rw] start_after
    #   If StartAfter was sent with the request, it is included in the
    #   response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsV2Output AWS API Documentation
    #
    class ListObjectsV2Output < Struct.new(
      :is_truncated,
      :contents,
      :name,
      :prefix,
      :delimiter,
      :max_keys,
      :common_prefixes,
      :encoding_type,
      :key_count,
      :continuation_token,
      :next_continuation_token,
      :start_after)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListObjectsV2Request
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         delimiter: "Delimiter",
    #         encoding_type: "url", # accepts url
    #         max_keys: 1,
    #         prefix: "Prefix",
    #         continuation_token: "Token",
    #         fetch_owner: false,
    #         start_after: "StartAfter",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Bucket name to list.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] delimiter
    #   A delimiter is a character you use to group keys.
    #   @return [String]
    #
    # @!attribute [rw] encoding_type
    #   Encoding type used by Amazon S3 to encode object keys in the
    #   response.
    #   @return [String]
    #
    # @!attribute [rw] max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the API returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   Limits the response to keys that begin with the specified prefix.
    #   @return [String]
    #
    # @!attribute [rw] continuation_token
    #   ContinuationToken indicates Amazon S3 that the list is being
    #   continued on this bucket with a token. ContinuationToken is
    #   obfuscated and is not a real key.
    #   @return [String]
    #
    # @!attribute [rw] fetch_owner
    #   The owner field is not present in listV2 by default, if you want to
    #   return owner field with each key in the result then set the fetch
    #   owner field to true.
    #   @return [Boolean]
    #
    # @!attribute [rw] start_after
    #   StartAfter is where you want Amazon S3 to start listing from. Amazon
    #   S3 starts listing after this specified key. StartAfter can be any
    #   key in the bucket.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request in V2 style. Bucket owners need not specify
    #   this parameter in their requests.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsV2Request AWS API Documentation
    #
    class ListObjectsV2Request < Struct.new(
      :bucket,
      :delimiter,
      :encoding_type,
      :max_keys,
      :prefix,
      :continuation_token,
      :fetch_owner,
      :start_after,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] abort_date
    #   If the bucket has a lifecycle rule configured with an action to
    #   abort incomplete multipart uploads and the prefix in the lifecycle
    #   rule matches the object name in the request, then the response
    #   includes this header indicating when the initiated multipart upload
    #   will become eligible for abort operation. For more information, see
    #   [Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle
    #   Policy][1].
    #
    #   The response will also include the `x-amz-abort-rule-id` header that
    #   will provide the ID of the lifecycle configuration rule that defines
    #   this action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Time]
    #
    # @!attribute [rw] abort_rule_id
    #   This header is returned along with the `x-amz-abort-date` header. It
    #   identifies applicable lifecycle configuration rule that defines the
    #   action to abort incomplete multipart uploads.
    #   @return [String]
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose parts are being
    #   listed.
    #   @return [String]
    #
    # @!attribute [rw] part_number_marker
    #   When a list is truncated, this element specifies the last part in
    #   the list, as well as the value to use for the part-number-marker
    #   request parameter in a subsequent request.
    #   @return [Integer]
    #
    # @!attribute [rw] next_part_number_marker
    #   When a list is truncated, this element specifies the last part in
    #   the list, as well as the value to use for the part-number-marker
    #   request parameter in a subsequent request.
    #   @return [Integer]
    #
    # @!attribute [rw] max_parts
    #   Maximum number of parts that were allowed in the response.
    #   @return [Integer]
    #
    # @!attribute [rw] is_truncated
    #   Indicates whether the returned list of parts is truncated. A true
    #   value indicates that the list was truncated. A list can be truncated
    #   if the number of parts exceeds the limit returned in the MaxParts
    #   element.
    #   @return [Boolean]
    #
    # @!attribute [rw] parts
    #   Container for elements related to a particular part. A response can
    #   contain zero or more `Part` elements.
    #   @return [Array<Types::Part>]
    #
    # @!attribute [rw] initiator
    #   Container element that identifies who initiated the multipart
    #   upload. If the initiator is an AWS account, this element provides
    #   the same information as the `Owner` element. If the initiator is an
    #   IAM User, this element provides the user ARN and display name.
    #   @return [Types::Initiator]
    #
    # @!attribute [rw] owner
    #   Container element that identifies the object owner, after the object
    #   is created. If multipart upload is initiated by an IAM user, this
    #   element provides the parent account ID and display name.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] storage_class
    #   Class of storage (STANDARD or REDUCED\_REDUNDANCY) used to store the
    #   uploaded object.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListPartsOutput AWS API Documentation
    #
    class ListPartsOutput < Struct.new(
      :abort_date,
      :abort_rule_id,
      :bucket,
      :key,
      :upload_id,
      :part_number_marker,
      :next_part_number_marker,
      :max_parts,
      :is_truncated,
      :parts,
      :initiator,
      :owner,
      :storage_class,
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListPartsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         max_parts: 1,
    #         part_number_marker: 1,
    #         upload_id: "MultipartUploadId", # required
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the parts are being uploaded.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] max_parts
    #   Sets the maximum number of parts to return.
    #   @return [Integer]
    #
    # @!attribute [rw] part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose parts are being
    #   listed.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListPartsRequest AWS API Documentation
    #
    class ListPartsRequest < Struct.new(
      :bucket,
      :key,
      :max_parts,
      :part_number_marker,
      :upload_id,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes where logs are stored and the prefix that Amazon S3 assigns
    # to all log object keys for a bucket. For more information, see [PUT
    # Bucket logging][1] in the *Amazon Simple Storage Service API
    # Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
    #
    # @note When making an API call, you may pass LoggingEnabled
    #   data as a hash:
    #
    #       {
    #         target_bucket: "TargetBucket", # required
    #         target_grants: [
    #           {
    #             grantee: {
    #               display_name: "DisplayName",
    #               email_address: "EmailAddress",
    #               id: "ID",
    #               type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #               uri: "URI",
    #             },
    #             permission: "FULL_CONTROL", # accepts FULL_CONTROL, READ, WRITE
    #           },
    #         ],
    #         target_prefix: "TargetPrefix", # required
    #       }
    #
    # @!attribute [rw] target_bucket
    #   Specifies the bucket where you want Amazon S3 to store server access
    #   logs. You can have your logs delivered to any bucket that you own,
    #   including the same bucket that is being logged. You can also
    #   configure multiple buckets to deliver their logs to the same target
    #   bucket. In this case, you should choose a different `TargetPrefix`
    #   for each source bucket so that the delivered log files can be
    #   distinguished by key.
    #   @return [String]
    #
    # @!attribute [rw] target_grants
    #   Container for granting information.
    #   @return [Array<Types::TargetGrant>]
    #
    # @!attribute [rw] target_prefix
    #   A prefix for all log object keys. If you store log files from
    #   multiple Amazon S3 buckets in a single bucket, you can use a prefix
    #   to distinguish which log files came from which bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/LoggingEnabled AWS API Documentation
    #
    class LoggingEnabled < Struct.new(
      :target_bucket,
      :target_grants,
      :target_prefix)
      SENSITIVE = []
      include Aws::Structure
    end

    # A metadata key-value pair to store with an object.
    #
    # @note When making an API call, you may pass MetadataEntry
    #   data as a hash:
    #
    #       {
    #         name: "MetadataKey",
    #         value: "MetadataValue",
    #       }
    #
    # @!attribute [rw] name
    #   Name of the Object.
    #   @return [String]
    #
    # @!attribute [rw] value
    #   Value of the Object.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetadataEntry AWS API Documentation
    #
    class MetadataEntry < Struct.new(
      :name,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying replication metrics-related settings enabling
    # metrics and Amazon S3 events for S3 Replication Time Control (S3 RTC).
    # Must be specified together with a `ReplicationTime` block.
    #
    # @note When making an API call, you may pass Metrics
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #         event_threshold: { # required
    #           minutes: 1,
    #         },
    #       }
    #
    # @!attribute [rw] status
    #   Specifies whether the replication metrics are enabled.
    #   @return [String]
    #
    # @!attribute [rw] event_threshold
    #   A container specifying the time threshold for emitting the
    #   `s3:Replication:OperationMissedThreshold` event.
    #   @return [Types::ReplicationTimeValue]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Metrics AWS API Documentation
    #
    class Metrics < Struct.new(
      :status,
      :event_threshold)
      SENSITIVE = []
      include Aws::Structure
    end

    # A conjunction (logical AND) of predicates, which is used in evaluating
    # a metrics filter. The operator must have at least two predicates, and
    # an object must match all of the predicates in order for the filter to
    # apply.
    #
    # @note When making an API call, you may pass MetricsAndOperator
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tags: [
    #           {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] prefix
    #   The prefix used when evaluating an AND predicate.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   The list of tags used when evaluating an AND predicate.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsAndOperator AWS API Documentation
    #
    class MetricsAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a metrics configuration for the CloudWatch request metrics
    # (specified by the metrics configuration ID) from an Amazon S3 bucket.
    # If you're updating an existing metrics configuration, note that this
    # is a full replacement of the existing metrics configuration. If you
    # don't include the elements you want to keep, they are erased. For
    # more information, see [ PUT Bucket metrics][1] in the *Amazon Simple
    # Storage Service API Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTMetricConfiguration.html
    #
    # @note When making an API call, you may pass MetricsConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "MetricsId", # required
    #         filter: {
    #           prefix: "Prefix",
    #           tag: {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #           and: {
    #             prefix: "Prefix",
    #             tags: [
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   Specifies a metrics configuration filter. The metrics configuration
    #   will only include objects that meet the filter's criteria. A filter
    #   must be a prefix, a tag, or a conjunction (MetricsAndOperator).
    #   @return [Types::MetricsFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsConfiguration AWS API Documentation
    #
    class MetricsConfiguration < Struct.new(
      :id,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies a metrics configuration filter. The metrics configuration
    # only includes objects that meet the filter's criteria. A filter must
    # be a prefix, a tag, or a conjunction (MetricsAndOperator).
    #
    # @note When making an API call, you may pass MetricsFilter
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       }
    #
    # @!attribute [rw] prefix
    #   The prefix used when evaluating a metrics filter.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   The tag used when evaluating a metrics filter.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A conjunction (logical AND) of predicates, which is used in
    #   evaluating a metrics filter. The operator must have at least two
    #   predicates, and an object must match all of the predicates in order
    #   for the filter to apply.
    #   @return [Types::MetricsAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MetricsFilter AWS API Documentation
    #
    class MetricsFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the `MultipartUpload` for the Amazon S3 object.
    #
    # @!attribute [rw] upload_id
    #   Upload ID that identifies the multipart upload.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key of the object for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] initiated
    #   Date and time at which the multipart upload was initiated.
    #   @return [Time]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @!attribute [rw] owner
    #   Specifies the owner of the object that is part of the multipart
    #   upload.
    #   @return [Types::Owner]
    #
    # @!attribute [rw] initiator
    #   Identifies who initiated the multipart upload.
    #   @return [Types::Initiator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/MultipartUpload AWS API Documentation
    #
    class MultipartUpload < Struct.new(
      :upload_id,
      :key,
      :initiated,
      :storage_class,
      :owner,
      :initiator)
      SENSITIVE = []
      include Aws::Structure
    end

    # The specified bucket does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchBucket AWS API Documentation
    #
    class NoSuchBucket < Aws::EmptyStructure; end

    # The specified key does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchKey AWS API Documentation
    #
    class NoSuchKey < Aws::EmptyStructure; end

    # The specified multipart upload does not exist.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoSuchUpload AWS API Documentation
    #
    class NoSuchUpload < Aws::EmptyStructure; end

    # Specifies when noncurrent object versions expire. Upon expiration,
    # Amazon S3 permanently deletes the noncurrent object versions. You set
    # this lifecycle configuration action on a bucket that has versioning
    # enabled (or suspended) to request that Amazon S3 delete noncurrent
    # object versions at a specific period in the object's lifetime.
    #
    # @note When making an API call, you may pass NoncurrentVersionExpiration
    #   data as a hash:
    #
    #       {
    #         noncurrent_days: 1,
    #       }
    #
    # @!attribute [rw] noncurrent_days
    #   Specifies the number of days an object is noncurrent before Amazon
    #   S3 can perform the associated action. For information about the
    #   noncurrent days calculations, see [How Amazon S3 Calculates When an
    #   Object Became Noncurrent][1] in the *Amazon Simple Storage Service
    #   Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#non-current-days-calculations
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoncurrentVersionExpiration AWS API Documentation
    #
    class NoncurrentVersionExpiration < Struct.new(
      :noncurrent_days)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the transition rule that describes when noncurrent
    # objects transition to the `STANDARD_IA`, `ONEZONE_IA`,
    # `INTELLIGENT_TIERING`, `GLACIER`, or `DEEP_ARCHIVE` storage class. If
    # your bucket is versioning-enabled (or versioning is suspended), you
    # can set this action to request that Amazon S3 transition noncurrent
    # object versions to the `STANDARD_IA`, `ONEZONE_IA`,
    # `INTELLIGENT_TIERING`, `GLACIER`, or `DEEP_ARCHIVE` storage class at a
    # specific period in the object's lifetime.
    #
    # @note When making an API call, you may pass NoncurrentVersionTransition
    #   data as a hash:
    #
    #       {
    #         noncurrent_days: 1,
    #         storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #       }
    #
    # @!attribute [rw] noncurrent_days
    #   Specifies the number of days an object is noncurrent before Amazon
    #   S3 can perform the associated action. For information about the
    #   noncurrent days calculations, see [How Amazon S3 Calculates How Long
    #   an Object Has Been Noncurrent][1] in the *Amazon Simple Storage
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#non-current-days-calculations
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NoncurrentVersionTransition AWS API Documentation
    #
    class NoncurrentVersionTransition < Struct.new(
      :noncurrent_days,
      :storage_class)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the notification configuration of the
    # bucket. If this element is empty, notifications are turned off for the
    # bucket.
    #
    # @note When making an API call, you may pass NotificationConfiguration
    #   data as a hash:
    #
    #       {
    #         topic_configurations: [
    #           {
    #             id: "NotificationId",
    #             topic_arn: "TopicArn", # required
    #             events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             filter: {
    #               key: {
    #                 filter_rules: [
    #                   {
    #                     name: "prefix", # accepts prefix, suffix
    #                     value: "FilterRuleValue",
    #                   },
    #                 ],
    #               },
    #             },
    #           },
    #         ],
    #         queue_configurations: [
    #           {
    #             id: "NotificationId",
    #             queue_arn: "QueueArn", # required
    #             events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             filter: {
    #               key: {
    #                 filter_rules: [
    #                   {
    #                     name: "prefix", # accepts prefix, suffix
    #                     value: "FilterRuleValue",
    #                   },
    #                 ],
    #               },
    #             },
    #           },
    #         ],
    #         lambda_function_configurations: [
    #           {
    #             id: "NotificationId",
    #             lambda_function_arn: "LambdaFunctionArn", # required
    #             events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             filter: {
    #               key: {
    #                 filter_rules: [
    #                   {
    #                     name: "prefix", # accepts prefix, suffix
    #                     value: "FilterRuleValue",
    #                   },
    #                 ],
    #               },
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] topic_configurations
    #   The topic to which notifications are sent and the events for which
    #   notifications are generated.
    #   @return [Array<Types::TopicConfiguration>]
    #
    # @!attribute [rw] queue_configurations
    #   The Amazon Simple Queue Service queues to publish messages to and
    #   the events for which to publish messages.
    #   @return [Array<Types::QueueConfiguration>]
    #
    # @!attribute [rw] lambda_function_configurations
    #   Describes the AWS Lambda functions to invoke and the events for
    #   which to invoke them.
    #   @return [Array<Types::LambdaFunctionConfiguration>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfiguration AWS API Documentation
    #
    class NotificationConfiguration < Struct.new(
      :topic_configurations,
      :queue_configurations,
      :lambda_function_configurations)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass NotificationConfigurationDeprecated
    #   data as a hash:
    #
    #       {
    #         topic_configuration: {
    #           id: "NotificationId",
    #           events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           topic: "TopicArn",
    #         },
    #         queue_configuration: {
    #           id: "NotificationId",
    #           event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           queue: "QueueArn",
    #         },
    #         cloud_function_configuration: {
    #           id: "NotificationId",
    #           event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #           cloud_function: "CloudFunction",
    #           invocation_role: "CloudFunctionInvocationRole",
    #         },
    #       }
    #
    # @!attribute [rw] topic_configuration
    #   This data type is deprecated. A container for specifying the
    #   configuration for publication of messages to an Amazon Simple
    #   Notification Service (Amazon SNS) topic when Amazon S3 detects
    #   specified events.
    #   @return [Types::TopicConfigurationDeprecated]
    #
    # @!attribute [rw] queue_configuration
    #   This data type is deprecated. This data type specifies the
    #   configuration for publishing messages to an Amazon Simple Queue
    #   Service (Amazon SQS) queue when Amazon S3 detects specified events.
    #   @return [Types::QueueConfigurationDeprecated]
    #
    # @!attribute [rw] cloud_function_configuration
    #   Container for specifying the AWS Lambda notification configuration.
    #   @return [Types::CloudFunctionConfiguration]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfigurationDeprecated AWS API Documentation
    #
    class NotificationConfigurationDeprecated < Struct.new(
      :topic_configuration,
      :queue_configuration,
      :cloud_function_configuration)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies object key name filtering rules. For information about key
    # name filtering, see [Configuring Event Notifications][1] in the
    # *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #
    # @note When making an API call, you may pass NotificationConfigurationFilter
    #   data as a hash:
    #
    #       {
    #         key: {
    #           filter_rules: [
    #             {
    #               name: "prefix", # accepts prefix, suffix
    #               value: "FilterRuleValue",
    #             },
    #           ],
    #         },
    #       }
    #
    # @!attribute [rw] key
    #   A container for object key name prefix and suffix filtering rules.
    #   @return [Types::S3KeyFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/NotificationConfigurationFilter AWS API Documentation
    #
    class NotificationConfigurationFilter < Struct.new(
      :key)
      SENSITIVE = []
      include Aws::Structure
    end

    # An object consists of data and its descriptive metadata.
    #
    # @!attribute [rw] key
    #   The name that you assign to an object. You use the object key to
    #   retrieve the object.
    #   @return [String]
    #
    # @!attribute [rw] last_modified
    #   The date the Object was Last Modified
    #   @return [Time]
    #
    # @!attribute [rw] etag
    #   The entity tag is a hash of the object. The ETag reflects changes
    #   only to the contents of an object, not its metadata. The ETag may or
    #   may not be an MD5 digest of the object data. Whether or not it is
    #   depends on how the object was created and how it is encrypted as
    #   described below:
    #
    #   * Objects created by the PUT Object, POST Object, or Copy operation,
    #     or through the AWS Management Console, and are encrypted by SSE-S3
    #     or plaintext, have ETags that are an MD5 digest of their object
    #     data.
    #
    #   * Objects created by the PUT Object, POST Object, or Copy operation,
    #     or through the AWS Management Console, and are encrypted by SSE-C
    #     or SSE-KMS, have ETags that are not an MD5 digest of their object
    #     data.
    #
    #   * If an object is created by either the Multipart Upload or Part
    #     Copy operation, the ETag is not an MD5 digest, regardless of the
    #     method of encryption.
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the object
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @!attribute [rw] owner
    #   The owner of the object
    #   @return [Types::Owner]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Object AWS API Documentation
    #
    class Object < Struct.new(
      :key,
      :last_modified,
      :etag,
      :size,
      :storage_class,
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # This operation is not allowed against this storage tier.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectAlreadyInActiveTierError AWS API Documentation
    #
    class ObjectAlreadyInActiveTierError < Aws::EmptyStructure; end

    # Object Identifier is unique value to identify objects.
    #
    # @note When making an API call, you may pass ObjectIdentifier
    #   data as a hash:
    #
    #       {
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #       }
    #
    # @!attribute [rw] key
    #   Key name of the object to delete.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId for the specific version of the object to delete.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectIdentifier AWS API Documentation
    #
    class ObjectIdentifier < Struct.new(
      :key,
      :version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for Object Lock configuration parameters.
    #
    # @note When making an API call, you may pass ObjectLockConfiguration
    #   data as a hash:
    #
    #       {
    #         object_lock_enabled: "Enabled", # accepts Enabled
    #         rule: {
    #           default_retention: {
    #             mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #             days: 1,
    #             years: 1,
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] object_lock_enabled
    #   Indicates whether this bucket has an Object Lock configuration
    #   enabled.
    #   @return [String]
    #
    # @!attribute [rw] rule
    #   The Object Lock rule in place for the specified object.
    #   @return [Types::ObjectLockRule]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockConfiguration AWS API Documentation
    #
    class ObjectLockConfiguration < Struct.new(
      :object_lock_enabled,
      :rule)
      SENSITIVE = []
      include Aws::Structure
    end

    # A Legal Hold configuration for an object.
    #
    # @note When making an API call, you may pass ObjectLockLegalHold
    #   data as a hash:
    #
    #       {
    #         status: "ON", # accepts ON, OFF
    #       }
    #
    # @!attribute [rw] status
    #   Indicates whether the specified object has a Legal Hold in place.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockLegalHold AWS API Documentation
    #
    class ObjectLockLegalHold < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # A Retention configuration for an object.
    #
    # @note When making an API call, you may pass ObjectLockRetention
    #   data as a hash:
    #
    #       {
    #         mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #         retain_until_date: Time.now,
    #       }
    #
    # @!attribute [rw] mode
    #   Indicates the Retention mode for the specified object.
    #   @return [String]
    #
    # @!attribute [rw] retain_until_date
    #   The date on which this Object Lock Retention will expire.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockRetention AWS API Documentation
    #
    class ObjectLockRetention < Struct.new(
      :mode,
      :retain_until_date)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for an Object Lock rule.
    #
    # @note When making an API call, you may pass ObjectLockRule
    #   data as a hash:
    #
    #       {
    #         default_retention: {
    #           mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #           days: 1,
    #           years: 1,
    #         },
    #       }
    #
    # @!attribute [rw] default_retention
    #   The default retention period that you want to apply to new objects
    #   placed in the specified bucket.
    #   @return [Types::DefaultRetention]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectLockRule AWS API Documentation
    #
    class ObjectLockRule < Struct.new(
      :default_retention)
      SENSITIVE = []
      include Aws::Structure
    end

    # The source object of the COPY operation is not in the active tier and
    # is only stored in Amazon S3 Glacier.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectNotInActiveTierError AWS API Documentation
    #
    class ObjectNotInActiveTierError < Aws::EmptyStructure; end

    # The version of an object.
    #
    # @!attribute [rw] etag
    #   The entity tag is an MD5 hash of that version of the object.
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the object.
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version ID of an object.
    #   @return [String]
    #
    # @!attribute [rw] is_latest
    #   Specifies whether the object is (true) or is not (false) the latest
    #   version of an object.
    #   @return [Boolean]
    #
    # @!attribute [rw] last_modified
    #   Date and time the object was last modified.
    #   @return [Time]
    #
    # @!attribute [rw] owner
    #   Specifies the owner of the object.
    #   @return [Types::Owner]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ObjectVersion AWS API Documentation
    #
    class ObjectVersion < Struct.new(
      :etag,
      :size,
      :storage_class,
      :key,
      :version_id,
      :is_latest,
      :last_modified,
      :owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the location where the restore job's output is stored.
    #
    # @note When making an API call, you may pass OutputLocation
    #   data as a hash:
    #
    #       {
    #         s3: {
    #           bucket_name: "BucketName", # required
    #           prefix: "LocationPrefix", # required
    #           encryption: {
    #             encryption_type: "AES256", # required, accepts AES256, aws:kms
    #             kms_key_id: "SSEKMSKeyId",
    #             kms_context: "KMSContext",
    #           },
    #           canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #           access_control_list: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #             },
    #           ],
    #           tagging: {
    #             tag_set: [ # required
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #           user_metadata: [
    #             {
    #               name: "MetadataKey",
    #               value: "MetadataValue",
    #             },
    #           ],
    #           storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #         },
    #       }
    #
    # @!attribute [rw] s3
    #   Describes an S3 location that will receive the results of the
    #   restore request.
    #   @return [Types::S3Location]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OutputLocation AWS API Documentation
    #
    class OutputLocation < Struct.new(
      :s3)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes how results of the Select job are serialized.
    #
    # @note When making an API call, you may pass OutputSerialization
    #   data as a hash:
    #
    #       {
    #         csv: {
    #           quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #           quote_escape_character: "QuoteEscapeCharacter",
    #           record_delimiter: "RecordDelimiter",
    #           field_delimiter: "FieldDelimiter",
    #           quote_character: "QuoteCharacter",
    #         },
    #         json: {
    #           record_delimiter: "RecordDelimiter",
    #         },
    #       }
    #
    # @!attribute [rw] csv
    #   Describes the serialization of CSV-encoded Select results.
    #   @return [Types::CSVOutput]
    #
    # @!attribute [rw] json
    #   Specifies JSON as request's output serialization format.
    #   @return [Types::JSONOutput]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/OutputSerialization AWS API Documentation
    #
    class OutputSerialization < Struct.new(
      :csv,
      :json)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the owner's display name and ID.
    #
    # @note When making an API call, you may pass Owner
    #   data as a hash:
    #
    #       {
    #         display_name: "DisplayName",
    #         id: "ID",
    #       }
    #
    # @!attribute [rw] display_name
    #   Container for the display name of the owner.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   Container for the ID of the owner.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Owner AWS API Documentation
    #
    class Owner < Struct.new(
      :display_name,
      :id)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for Parquet.
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ParquetInput AWS API Documentation
    #
    class ParquetInput < Aws::EmptyStructure; end

    # Container for elements related to a part.
    #
    # @!attribute [rw] part_number
    #   Part number identifying the part. This is a positive integer between
    #   1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] last_modified
    #   Date and time at which the part was uploaded.
    #   @return [Time]
    #
    # @!attribute [rw] etag
    #   Entity tag returned when the part was uploaded.
    #   @return [String]
    #
    # @!attribute [rw] size
    #   Size in bytes of the uploaded part data.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Part AWS API Documentation
    #
    class Part < Struct.new(
      :part_number,
      :last_modified,
      :etag,
      :size)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container element for a bucket's policy status.
    #
    # @!attribute [rw] is_public
    #   The policy status for this bucket. `TRUE` indicates that this bucket
    #   is public. `FALSE` indicates that the bucket is not public.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PolicyStatus AWS API Documentation
    #
    class PolicyStatus < Struct.new(
      :is_public)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type contains information about progress of an operation.
    #
    # @!attribute [rw] bytes_scanned
    #   The current number of object bytes scanned.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_processed
    #   The current number of uncompressed object bytes processed.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_returned
    #   The current number of bytes of records payload data returned.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Progress AWS API Documentation
    #
    class Progress < Struct.new(
      :bytes_scanned,
      :bytes_processed,
      :bytes_returned)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type contains information about the progress event of an
    # operation.
    #
    # @!attribute [rw] details
    #   The Progress event details.
    #   @return [Types::Progress]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ProgressEvent AWS API Documentation
    #
    class ProgressEvent < Struct.new(
      :details,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # The PublicAccessBlock configuration that you want to apply to this
    # Amazon S3 bucket. You can enable the configuration options in any
    # combination. For more information about when Amazon S3 considers a
    # bucket or object public, see [The Meaning of "Public"][1] in the
    # *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    #
    # @note When making an API call, you may pass PublicAccessBlockConfiguration
    #   data as a hash:
    #
    #       {
    #         block_public_acls: false,
    #         ignore_public_acls: false,
    #         block_public_policy: false,
    #         restrict_public_buckets: false,
    #       }
    #
    # @!attribute [rw] block_public_acls
    #   Specifies whether Amazon S3 should block public access control lists
    #   (ACLs) for this bucket and objects in this bucket. Setting this
    #   element to `TRUE` causes the following behavior:
    #
    #   * PUT Bucket acl and PUT Object acl calls fail if the specified ACL
    #     is public.
    #
    #   * PUT Object calls fail if the request includes a public ACL.
    #
    #   * PUT Bucket calls fail if the request includes a public ACL.
    #
    #   Enabling this setting doesn't affect existing policies or ACLs.
    #   @return [Boolean]
    #
    # @!attribute [rw] ignore_public_acls
    #   Specifies whether Amazon S3 should ignore public ACLs for this
    #   bucket and objects in this bucket. Setting this element to `TRUE`
    #   causes Amazon S3 to ignore all public ACLs on this bucket and
    #   objects in this bucket.
    #
    #   Enabling this setting doesn't affect the persistence of any
    #   existing ACLs and doesn't prevent new public ACLs from being set.
    #   @return [Boolean]
    #
    # @!attribute [rw] block_public_policy
    #   Specifies whether Amazon S3 should block public bucket policies for
    #   this bucket. Setting this element to `TRUE` causes Amazon S3 to
    #   reject calls to PUT Bucket policy if the specified bucket policy
    #   allows public access.
    #
    #   Enabling this setting doesn't affect existing bucket policies.
    #   @return [Boolean]
    #
    # @!attribute [rw] restrict_public_buckets
    #   Specifies whether Amazon S3 should restrict public bucket policies
    #   for this bucket. Setting this element to `TRUE` restricts access to
    #   this bucket to only AWS services and authorized users within this
    #   account if the bucket has a public policy.
    #
    #   Enabling this setting doesn't affect previously stored bucket
    #   policies, except that public and cross-account access within any
    #   public bucket policy, including non-public delegation to specific
    #   accounts, is blocked.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PublicAccessBlockConfiguration AWS API Documentation
    #
    class PublicAccessBlockConfiguration < Struct.new(
      :block_public_acls,
      :ignore_public_acls,
      :block_public_policy,
      :restrict_public_buckets)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketAccelerateConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         accelerate_configuration: { # required
    #           status: "Enabled", # accepts Enabled, Suspended
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Name of the bucket for which the accelerate configuration is set.
    #   @return [String]
    #
    # @!attribute [rw] accelerate_configuration
    #   Container for setting the transfer acceleration state.
    #   @return [Types::AccelerateConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAccelerateConfigurationRequest AWS API Documentation
    #
    class PutBucketAccelerateConfigurationRequest < Struct.new(
      :bucket,
      :accelerate_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketAclRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #         access_control_policy: {
    #           grants: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #             },
    #           ],
    #           owner: {
    #             display_name: "DisplayName",
    #             id: "ID",
    #           },
    #         },
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write: "GrantWrite",
    #         grant_write_acp: "GrantWriteACP",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the bucket.
    #   @return [String]
    #
    # @!attribute [rw] access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #   @return [Types::AccessControlPolicy]
    #
    # @!attribute [rw] bucket
    #   The bucket to which to apply the ACL.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must
    #   be used as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, go to [RFC
    #   1864.][1]
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create, overwrite, and delete any object in the
    #   bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAclRequest AWS API Documentation
    #
    class PutBucketAclRequest < Struct.new(
      :acl,
      :access_control_policy,
      :bucket,
      :content_md5,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketAnalyticsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "AnalyticsId", # required
    #         analytics_configuration: { # required
    #           id: "AnalyticsId", # required
    #           filter: {
    #             prefix: "Prefix",
    #             tag: {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #             and: {
    #               prefix: "Prefix",
    #               tags: [
    #                 {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #               ],
    #             },
    #           },
    #           storage_class_analysis: { # required
    #             data_export: {
    #               output_schema_version: "V_1", # required, accepts V_1
    #               destination: { # required
    #                 s3_bucket_destination: { # required
    #                   format: "CSV", # required, accepts CSV
    #                   bucket_account_id: "AccountId",
    #                   bucket: "BucketName", # required
    #                   prefix: "Prefix",
    #                 },
    #               },
    #             },
    #           },
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket to which an analytics configuration is
    #   stored.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID that identifies the analytics configuration.
    #   @return [String]
    #
    # @!attribute [rw] analytics_configuration
    #   The configuration and any analyses for the analytics filter.
    #   @return [Types::AnalyticsConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAnalyticsConfigurationRequest AWS API Documentation
    #
    class PutBucketAnalyticsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :analytics_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketCorsRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         cors_configuration: { # required
    #           cors_rules: [ # required
    #             {
    #               allowed_headers: ["AllowedHeader"],
    #               allowed_methods: ["AllowedMethod"], # required
    #               allowed_origins: ["AllowedOrigin"], # required
    #               expose_headers: ["ExposeHeader"],
    #               max_age_seconds: 1,
    #             },
    #           ],
    #         },
    #         content_md5: "ContentMD5",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Specifies the bucket impacted by the `cors`configuration.
    #   @return [String]
    #
    # @!attribute [rw] cors_configuration
    #   Describes the cross-origin access configuration for objects in an
    #   Amazon S3 bucket. For more information, see [Enabling Cross-Origin
    #   Resource Sharing][1] in the *Amazon Simple Storage Service Developer
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    #   @return [Types::CORSConfiguration]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must
    #   be used as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, go to [RFC
    #   1864.][1]
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketCorsRequest AWS API Documentation
    #
    class PutBucketCorsRequest < Struct.new(
      :bucket,
      :cors_configuration,
      :content_md5,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketEncryptionRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         server_side_encryption_configuration: { # required
    #           rules: [ # required
    #             {
    #               apply_server_side_encryption_by_default: {
    #                 sse_algorithm: "AES256", # required, accepts AES256, aws:kms
    #                 kms_master_key_id: "SSEKMSKeyId",
    #               },
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   Specifies default encryption for a bucket using server-side
    #   encryption with Amazon S3-managed keys (SSE-S3) or customer master
    #   keys stored in AWS KMS (SSE-KMS). For information about the Amazon
    #   S3 default encryption feature, see [Amazon S3 Default Bucket
    #   Encryption][1] in the *Amazon Simple Storage Service Developer
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the server-side encryption
    #   configuration. This parameter is auto-populated when using the
    #   command from the CLI.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption_configuration
    #   Specifies the default server-side-encryption configuration.
    #   @return [Types::ServerSideEncryptionConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketEncryptionRequest AWS API Documentation
    #
    class PutBucketEncryptionRequest < Struct.new(
      :bucket,
      :content_md5,
      :server_side_encryption_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketInventoryConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "InventoryId", # required
    #         inventory_configuration: { # required
    #           destination: { # required
    #             s3_bucket_destination: { # required
    #               account_id: "AccountId",
    #               bucket: "BucketName", # required
    #               format: "CSV", # required, accepts CSV, ORC, Parquet
    #               prefix: "Prefix",
    #               encryption: {
    #                 sses3: {
    #                 },
    #                 ssekms: {
    #                   key_id: "SSEKMSKeyId", # required
    #                 },
    #               },
    #             },
    #           },
    #           is_enabled: false, # required
    #           filter: {
    #             prefix: "Prefix", # required
    #           },
    #           id: "InventoryId", # required
    #           included_object_versions: "All", # required, accepts All, Current
    #           optional_fields: ["Size"], # accepts Size, LastModifiedDate, StorageClass, ETag, IsMultipartUploaded, ReplicationStatus, EncryptionStatus, ObjectLockRetainUntilDate, ObjectLockMode, ObjectLockLegalHoldStatus, IntelligentTieringAccessTier
    #           schedule: { # required
    #             frequency: "Daily", # required, accepts Daily, Weekly
    #           },
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket where the inventory configuration will be
    #   stored.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the inventory configuration.
    #   @return [String]
    #
    # @!attribute [rw] inventory_configuration
    #   Specifies the inventory configuration.
    #   @return [Types::InventoryConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketInventoryConfigurationRequest AWS API Documentation
    #
    class PutBucketInventoryConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :inventory_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketLifecycleConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         lifecycle_configuration: {
    #           rules: [ # required
    #             {
    #               expiration: {
    #                 date: Time.now,
    #                 days: 1,
    #                 expired_object_delete_marker: false,
    #               },
    #               id: "ID",
    #               prefix: "Prefix",
    #               filter: {
    #                 prefix: "Prefix",
    #                 tag: {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #                 and: {
    #                   prefix: "Prefix",
    #                   tags: [
    #                     {
    #                       key: "ObjectKey", # required
    #                       value: "Value", # required
    #                     },
    #                   ],
    #                 },
    #               },
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #               transitions: [
    #                 {
    #                   date: Time.now,
    #                   days: 1,
    #                   storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #                 },
    #               ],
    #               noncurrent_version_transitions: [
    #                 {
    #                   noncurrent_days: 1,
    #                   storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #                 },
    #               ],
    #               noncurrent_version_expiration: {
    #                 noncurrent_days: 1,
    #               },
    #               abort_incomplete_multipart_upload: {
    #                 days_after_initiation: 1,
    #               },
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to set the configuration.
    #   @return [String]
    #
    # @!attribute [rw] lifecycle_configuration
    #   Container for lifecycle rules. You can add as many as 1,000 rules.
    #   @return [Types::BucketLifecycleConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleConfigurationRequest AWS API Documentation
    #
    class PutBucketLifecycleConfigurationRequest < Struct.new(
      :bucket,
      :lifecycle_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketLifecycleRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         lifecycle_configuration: {
    #           rules: [ # required
    #             {
    #               expiration: {
    #                 date: Time.now,
    #                 days: 1,
    #                 expired_object_delete_marker: false,
    #               },
    #               id: "ID",
    #               prefix: "Prefix", # required
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #               transition: {
    #                 date: Time.now,
    #                 days: 1,
    #                 storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #               },
    #               noncurrent_version_transition: {
    #                 noncurrent_days: 1,
    #                 storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #               },
    #               noncurrent_version_expiration: {
    #                 noncurrent_days: 1,
    #               },
    #               abort_incomplete_multipart_upload: {
    #                 days_after_initiation: 1,
    #               },
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   @return [String]
    #
    # @!attribute [rw] lifecycle_configuration
    #   @return [Types::LifecycleConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleRequest AWS API Documentation
    #
    class PutBucketLifecycleRequest < Struct.new(
      :bucket,
      :content_md5,
      :lifecycle_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketLoggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         bucket_logging_status: { # required
    #           logging_enabled: {
    #             target_bucket: "TargetBucket", # required
    #             target_grants: [
    #               {
    #                 grantee: {
    #                   display_name: "DisplayName",
    #                   email_address: "EmailAddress",
    #                   id: "ID",
    #                   type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                   uri: "URI",
    #                 },
    #                 permission: "FULL_CONTROL", # accepts FULL_CONTROL, READ, WRITE
    #               },
    #             ],
    #             target_prefix: "TargetPrefix", # required
    #           },
    #         },
    #         content_md5: "ContentMD5",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which to set the logging parameters.
    #   @return [String]
    #
    # @!attribute [rw] bucket_logging_status
    #   Container for logging status information.
    #   @return [Types::BucketLoggingStatus]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutBucketLogging` request body.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLoggingRequest AWS API Documentation
    #
    class PutBucketLoggingRequest < Struct.new(
      :bucket,
      :bucket_logging_status,
      :content_md5,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketMetricsConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         id: "MetricsId", # required
    #         metrics_configuration: { # required
    #           id: "MetricsId", # required
    #           filter: {
    #             prefix: "Prefix",
    #             tag: {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #             and: {
    #               prefix: "Prefix",
    #               tags: [
    #                 {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #               ],
    #             },
    #           },
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket for which the metrics configuration is set.
    #   @return [String]
    #
    # @!attribute [rw] id
    #   The ID used to identify the metrics configuration.
    #   @return [String]
    #
    # @!attribute [rw] metrics_configuration
    #   Specifies the metrics configuration.
    #   @return [Types::MetricsConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketMetricsConfigurationRequest AWS API Documentation
    #
    class PutBucketMetricsConfigurationRequest < Struct.new(
      :bucket,
      :id,
      :metrics_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketNotificationConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         notification_configuration: { # required
    #           topic_configurations: [
    #             {
    #               id: "NotificationId",
    #               topic_arn: "TopicArn", # required
    #               events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #               filter: {
    #                 key: {
    #                   filter_rules: [
    #                     {
    #                       name: "prefix", # accepts prefix, suffix
    #                       value: "FilterRuleValue",
    #                     },
    #                   ],
    #                 },
    #               },
    #             },
    #           ],
    #           queue_configurations: [
    #             {
    #               id: "NotificationId",
    #               queue_arn: "QueueArn", # required
    #               events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #               filter: {
    #                 key: {
    #                   filter_rules: [
    #                     {
    #                       name: "prefix", # accepts prefix, suffix
    #                       value: "FilterRuleValue",
    #                     },
    #                   ],
    #                 },
    #               },
    #             },
    #           ],
    #           lambda_function_configurations: [
    #             {
    #               id: "NotificationId",
    #               lambda_function_arn: "LambdaFunctionArn", # required
    #               events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #               filter: {
    #                 key: {
    #                   filter_rules: [
    #                     {
    #                       name: "prefix", # accepts prefix, suffix
    #                       value: "FilterRuleValue",
    #                     },
    #                   ],
    #                 },
    #               },
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] notification_configuration
    #   A container for specifying the notification configuration of the
    #   bucket. If this element is empty, notifications are turned off for
    #   the bucket.
    #   @return [Types::NotificationConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotificationConfigurationRequest AWS API Documentation
    #
    class PutBucketNotificationConfigurationRequest < Struct.new(
      :bucket,
      :notification_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketNotificationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         notification_configuration: { # required
    #           topic_configuration: {
    #             id: "NotificationId",
    #             events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             topic: "TopicArn",
    #           },
    #           queue_configuration: {
    #             id: "NotificationId",
    #             event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             queue: "QueueArn",
    #           },
    #           cloud_function_configuration: {
    #             id: "NotificationId",
    #             event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #             cloud_function: "CloudFunction",
    #             invocation_role: "CloudFunctionInvocationRole",
    #           },
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #   @return [String]
    #
    # @!attribute [rw] notification_configuration
    #   The container for the configuration.
    #   @return [Types::NotificationConfigurationDeprecated]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotificationRequest AWS API Documentation
    #
    class PutBucketNotificationRequest < Struct.new(
      :bucket,
      :content_md5,
      :notification_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketPolicyRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         confirm_remove_self_bucket_access: false,
    #         policy: "Policy", # required
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the request body.
    #   @return [String]
    #
    # @!attribute [rw] confirm_remove_self_bucket_access
    #   Set this parameter to true to confirm that you want to remove your
    #   permissions to change this bucket policy in the future.
    #   @return [Boolean]
    #
    # @!attribute [rw] policy
    #   The bucket policy as a JSON document.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketPolicyRequest AWS API Documentation
    #
    class PutBucketPolicyRequest < Struct.new(
      :bucket,
      :content_md5,
      :confirm_remove_self_bucket_access,
      :policy,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketReplicationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         replication_configuration: { # required
    #           role: "Role", # required
    #           rules: [ # required
    #             {
    #               id: "ID",
    #               priority: 1,
    #               prefix: "Prefix",
    #               filter: {
    #                 prefix: "Prefix",
    #                 tag: {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #                 and: {
    #                   prefix: "Prefix",
    #                   tags: [
    #                     {
    #                       key: "ObjectKey", # required
    #                       value: "Value", # required
    #                     },
    #                   ],
    #                 },
    #               },
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #               source_selection_criteria: {
    #                 sse_kms_encrypted_objects: {
    #                   status: "Enabled", # required, accepts Enabled, Disabled
    #                 },
    #               },
    #               existing_object_replication: {
    #                 status: "Enabled", # required, accepts Enabled, Disabled
    #               },
    #               destination: { # required
    #                 bucket: "BucketName", # required
    #                 account: "AccountId",
    #                 storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #                 access_control_translation: {
    #                   owner: "Destination", # required, accepts Destination
    #                 },
    #                 encryption_configuration: {
    #                   replica_kms_key_id: "ReplicaKmsKeyID",
    #                 },
    #                 replication_time: {
    #                   status: "Enabled", # required, accepts Enabled, Disabled
    #                   time: { # required
    #                     minutes: 1,
    #                   },
    #                 },
    #                 metrics: {
    #                   status: "Enabled", # required, accepts Enabled, Disabled
    #                   event_threshold: { # required
    #                     minutes: 1,
    #                   },
    #                 },
    #               },
    #               delete_marker_replication: {
    #                 status: "Enabled", # accepts Enabled, Disabled
    #               },
    #             },
    #           ],
    #         },
    #         token: "ObjectLockToken",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the bucket
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] replication_configuration
    #   A container for replication rules. You can add up to 1,000 rules.
    #   The maximum size of a replication configuration is 2 MB.
    #   @return [Types::ReplicationConfiguration]
    #
    # @!attribute [rw] token
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketReplicationRequest AWS API Documentation
    #
    class PutBucketReplicationRequest < Struct.new(
      :bucket,
      :content_md5,
      :replication_configuration,
      :token,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketRequestPaymentRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         request_payment_configuration: { # required
    #           payer: "Requester", # required, accepts Requester, BucketOwner
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   &gt;The base64-encoded 128-bit MD5 digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] request_payment_configuration
    #   Container for Payer.
    #   @return [Types::RequestPaymentConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketRequestPaymentRequest AWS API Documentation
    #
    class PutBucketRequestPaymentRequest < Struct.new(
      :bucket,
      :content_md5,
      :request_payment_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         tagging: { # required
    #           tag_set: [ # required
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   Container for the `TagSet` and `Tag` elements.
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketTaggingRequest AWS API Documentation
    #
    class PutBucketTaggingRequest < Struct.new(
      :bucket,
      :content_md5,
      :tagging,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketVersioningRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         mfa: "MFA",
    #         versioning_configuration: { # required
    #           mfa_delete: "Enabled", # accepts Enabled, Disabled
    #           status: "Enabled", # accepts Enabled, Suspended
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   &gt;The base64-encoded 128-bit MD5 digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication
    #   device.
    #   @return [String]
    #
    # @!attribute [rw] versioning_configuration
    #   Container for setting the versioning state.
    #   @return [Types::VersioningConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketVersioningRequest AWS API Documentation
    #
    class PutBucketVersioningRequest < Struct.new(
      :bucket,
      :content_md5,
      :mfa,
      :versioning_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutBucketWebsiteRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         website_configuration: { # required
    #           error_document: {
    #             key: "ObjectKey", # required
    #           },
    #           index_document: {
    #             suffix: "Suffix", # required
    #           },
    #           redirect_all_requests_to: {
    #             host_name: "HostName", # required
    #             protocol: "http", # accepts http, https
    #           },
    #           routing_rules: [
    #             {
    #               condition: {
    #                 http_error_code_returned_equals: "HttpErrorCodeReturnedEquals",
    #                 key_prefix_equals: "KeyPrefixEquals",
    #               },
    #               redirect: { # required
    #                 host_name: "HostName",
    #                 http_redirect_code: "HttpRedirectCode",
    #                 protocol: "http", # accepts http, https
    #                 replace_key_prefix_with: "ReplaceKeyPrefixWith",
    #                 replace_key_with: "ReplaceKeyWith",
    #               },
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] website_configuration
    #   Container for the request.
    #   @return [Types::WebsiteConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketWebsiteRequest AWS API Documentation
    #
    class PutBucketWebsiteRequest < Struct.new(
      :bucket,
      :content_md5,
      :website_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectAclOutput AWS API Documentation
    #
    class PutObjectAclOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectAclRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #         access_control_policy: {
    #           grants: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #             },
    #           ],
    #           owner: {
    #             display_name: "DisplayName",
    #             id: "ID",
    #           },
    #         },
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write: "GrantWrite",
    #         grant_write_acp: "GrantWriteACP",
    #         key: "ObjectKey", # required
    #         request_payer: "requester", # accepts requester
    #         version_id: "ObjectVersionId",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #   @return [String]
    #
    # @!attribute [rw] access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #   @return [Types::AccessControlPolicy]
    #
    # @!attribute [rw] bucket
    #   The bucket name that contains the object to which you want to attach
    #   the ACL.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must
    #   be used as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, go to [RFC
    #   1864.&gt;][1]
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #   @return [String]
    #
    # @!attribute [rw] grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions
    #   on the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to list the objects in the bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write
    #   Allows grantee to create, overwrite, and delete any object in the
    #   bucket.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Key for which the PUT operation was initiated.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectAclRequest AWS API Documentation
    #
    class PutObjectAclRequest < Struct.new(
      :acl,
      :access_control_policy,
      :bucket,
      :content_md5,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write,
      :grant_write_acp,
      :key,
      :request_payer,
      :version_id,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLegalHoldOutput AWS API Documentation
    #
    class PutObjectLegalHoldOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectLegalHoldRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         legal_hold: {
    #           status: "ON", # accepts ON, OFF
    #         },
    #         request_payer: "requester", # accepts requester
    #         version_id: "ObjectVersionId",
    #         content_md5: "ContentMD5",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object that you want to place a Legal
    #   Hold on.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object that you want to place a Legal Hold on.
    #   @return [String]
    #
    # @!attribute [rw] legal_hold
    #   Container element for the Legal Hold configuration you want to apply
    #   to the specified object.
    #   @return [Types::ObjectLockLegalHold]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID of the object that you want to place a Legal Hold on.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLegalHoldRequest AWS API Documentation
    #
    class PutObjectLegalHoldRequest < Struct.new(
      :bucket,
      :key,
      :legal_hold,
      :request_payer,
      :version_id,
      :content_md5,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLockConfigurationOutput AWS API Documentation
    #
    class PutObjectLockConfigurationOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectLockConfigurationRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         object_lock_configuration: {
    #           object_lock_enabled: "Enabled", # accepts Enabled
    #           rule: {
    #             default_retention: {
    #               mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #               days: 1,
    #               years: 1,
    #             },
    #           },
    #         },
    #         request_payer: "requester", # accepts requester
    #         token: "ObjectLockToken",
    #         content_md5: "ContentMD5",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket whose Object Lock configuration you want to create or
    #   replace.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_configuration
    #   The Object Lock configuration that you want to apply to the
    #   specified bucket.
    #   @return [Types::ObjectLockConfiguration]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] token
    #   A token to allow Object Lock to be enabled for an existing bucket.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLockConfigurationRequest AWS API Documentation
    #
    class PutObjectLockConfigurationRequest < Struct.new(
      :bucket,
      :object_lock_configuration,
      :request_payer,
      :token,
      :content_md5,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] expiration
    #   If the expiration is configured for the object (see
    #   [PutBucketLifecycleConfiguration][1]), the response includes this
    #   header. It includes the expiry-date and rule-id key-value pairs that
    #   provide information about object expiration. The value of the
    #   rule-id is URL encoded.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag for the uploaded object.
    #   @return [String]
    #
    # @!attribute [rw] server_side_encryption
    #   If you specified server-side encryption either with an AWS KMS
    #   customer master key (CMK) or Amazon S3-managed encryption key in
    #   your PUT request, the response includes this header. It confirms the
    #   encryption algorithm that Amazon S3 used to encrypt the object.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   Version of the object.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If `x-amz-server-side-encryption` is present and has the value of
    #   `aws:kms`, this header specifies the ID of the AWS Key Management
    #   Service (AWS KMS) symmetric customer managed customer master key
    #   (CMK) that was used for the object.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   If present, specifies the AWS KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded
    #   UTF-8 string holding JSON with the encryption context key-value
    #   pairs.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectOutput AWS API Documentation
    #
    class PutObjectOutput < Struct.new(
      :expiration,
      :etag,
      :server_side_encryption,
      :version_id,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :request_charged)
      SENSITIVE = [:ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectRequest
    #   data as a hash:
    #
    #       {
    #         acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #         body: source_file,
    #         bucket: "BucketName", # required
    #         cache_control: "CacheControl",
    #         content_disposition: "ContentDisposition",
    #         content_encoding: "ContentEncoding",
    #         content_language: "ContentLanguage",
    #         content_length: 1,
    #         content_md5: "ContentMD5",
    #         content_type: "ContentType",
    #         expires: Time.now,
    #         grant_full_control: "GrantFullControl",
    #         grant_read: "GrantRead",
    #         grant_read_acp: "GrantReadACP",
    #         grant_write_acp: "GrantWriteACP",
    #         key: "ObjectKey", # required
    #         metadata: {
    #           "MetadataKey" => "MetadataValue",
    #         },
    #         server_side_encryption: "AES256", # accepts AES256, aws:kms
    #         storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #         website_redirect_location: "WebsiteRedirectLocation",
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         ssekms_key_id: "SSEKMSKeyId",
    #         ssekms_encryption_context: "SSEKMSEncryptionContext",
    #         request_payer: "requester", # accepts requester
    #         tagging: "TaggingHeader",
    #         object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #         object_lock_retain_until_date: Time.now,
    #         object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #   @return [String]
    #
    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] bucket
    #   Bucket name to which the PUT operation was initiated.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] cache_control
    #   Can be used to specify caching behavior along the request/reply
    #   chain. For more information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
    #   @return [String]
    #
    # @!attribute [rw] content_disposition
    #   Specifies presentational information for the object. For more
    #   information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.5.1][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.5.1
    #   @return [String]
    #
    # @!attribute [rw] content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the
    #   media-type referenced by the Content-Type header field. For more
    #   information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11
    #   @return [String]
    #
    # @!attribute [rw] content_language
    #   The language the content is in.
    #   @return [String]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically. For more information,
    #   see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.13][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.13
    #   @return [Integer]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the message (without the
    #   headers) according to RFC 1864. This header can be used as a message
    #   integrity check to verify that the data is the same data that was
    #   originally sent. Although it is optional, we recommend using the
    #   Content-MD5 mechanism as an end-to-end integrity check. For more
    #   information about REST request authentication, see [REST
    #   Authentication][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    #   @return [String]
    #
    # @!attribute [rw] content_type
    #   A standard MIME type describing the format of the contents. For more
    #   information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17
    #   @return [String]
    #
    # @!attribute [rw] expires
    #   The date and time at which the object is no longer cacheable. For
    #   more information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21
    #   @return [Time]
    #
    # @!attribute [rw] grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #   @return [String]
    #
    # @!attribute [rw] grant_read
    #   Allows grantee to read the object data and its metadata.
    #   @return [String]
    #
    # @!attribute [rw] grant_read_acp
    #   Allows grantee to read the object ACL.
    #   @return [String]
    #
    # @!attribute [rw] grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the PUT operation was initiated.
    #   @return [String]
    #
    # @!attribute [rw] metadata
    #   A map of metadata to store with the object in S3.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] storage_class
    #   If you don't specify, S3 Standard is the default storage class.
    #   Amazon S3 supports other storage classes.
    #   @return [String]
    #
    # @!attribute [rw] website_redirect_location
    #   If the bucket is configured as a website, redirects requests for
    #   this object to another object in the same bucket or to an external
    #   URL. Amazon S3 stores the value of this header in the object
    #   metadata. For information about object metadata, see [Object Key and
    #   Metadata][1].
    #
    #   In the following example, the request header sets the redirect to an
    #   object (anotherPage.html) in the same bucket:
    #
    #   `x-amz-website-redirect-location: /anotherPage.html`
    #
    #   In the following example, the request header sets the object
    #   redirect to another website:
    #
    #   `x-amz-website-redirect-location: http://www.example.com/`
    #
    #   For more information about website hosting in Amazon S3, see
    #   [Hosting Websites on Amazon S3][2] and [How to Configure Website
    #   Page Redirects][3].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If `x-amz-server-side-encryption` is present and has the value of
    #   `aws:kms`, this header specifies the ID of the AWS Key Management
    #   Service (AWS KMS) symmetrical customer managed customer master key
    #   (CMK) that was used for the object.
    #
    #   If the value of `x-amz-server-side-encryption` is `aws:kms`, this
    #   header specifies the ID of the symmetric customer managed AWS KMS
    #   CMK that will be used for the object. If you specify
    #   `x-amz-server-side-encryption:aws:kms`, but do not provide`
    #   x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the AWS
    #   managed CMK in AWS to protect the data.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_encryption_context
    #   Specifies the AWS KMS Encryption Context to use for object
    #   encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters. (For example, "Key1=Value1")
    #   @return [String]
    #
    # @!attribute [rw] object_lock_mode
    #   The Object Lock mode that you want to apply to this object.
    #   @return [String]
    #
    # @!attribute [rw] object_lock_retain_until_date
    #   The date and time when you want this object's Object Lock to
    #   expire.
    #   @return [Time]
    #
    # @!attribute [rw] object_lock_legal_hold_status
    #   Specifies whether a legal hold will be applied to this object. For
    #   more information about S3 Object Lock, see [Object Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRequest AWS API Documentation
    #
    class PutObjectRequest < Struct.new(
      :acl,
      :body,
      :bucket,
      :cache_control,
      :content_disposition,
      :content_encoding,
      :content_language,
      :content_length,
      :content_md5,
      :content_type,
      :expires,
      :grant_full_control,
      :grant_read,
      :grant_read_acp,
      :grant_write_acp,
      :key,
      :metadata,
      :server_side_encryption,
      :storage_class,
      :website_redirect_location,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :ssekms_encryption_context,
      :request_payer,
      :tagging,
      :object_lock_mode,
      :object_lock_retain_until_date,
      :object_lock_legal_hold_status,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key, :ssekms_key_id, :ssekms_encryption_context]
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRetentionOutput AWS API Documentation
    #
    class PutObjectRetentionOutput < Struct.new(
      :request_charged)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectRetentionRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         retention: {
    #           mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #           retain_until_date: Time.now,
    #         },
    #         request_payer: "requester", # accepts requester
    #         version_id: "ObjectVersionId",
    #         bypass_governance_retention: false,
    #         content_md5: "ContentMD5",
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name that contains the object you want to apply this
    #   Object Retention configuration to.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The key name for the object that you want to apply this Object
    #   Retention configuration to.
    #   @return [String]
    #
    # @!attribute [rw] retention
    #   The container element for the Object Retention configuration.
    #   @return [Types::ObjectLockRetention]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The version ID for the object that you want to apply this Object
    #   Retention configuration to.
    #   @return [String]
    #
    # @!attribute [rw] bypass_governance_retention
    #   Indicates whether this operation should bypass Governance-mode
    #   restrictions.
    #   @return [Boolean]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRetentionRequest AWS API Documentation
    #
    class PutObjectRetentionRequest < Struct.new(
      :bucket,
      :key,
      :retention,
      :request_payer,
      :version_id,
      :bypass_governance_retention,
      :content_md5,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] version_id
    #   The versionId of the object the tag-set was added to.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectTaggingOutput AWS API Documentation
    #
    class PutObjectTaggingOutput < Struct.new(
      :version_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutObjectTaggingRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         content_md5: "ContentMD5",
    #         tagging: { # required
    #           tag_set: [ # required
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name containing the object.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Name of the object key.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   The versionId of the object that the tag-set will be added to.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash for the request body.
    #   @return [String]
    #
    # @!attribute [rw] tagging
    #   Container for the `TagSet` and `Tag` elements
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectTaggingRequest AWS API Documentation
    #
    class PutObjectTaggingRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :content_md5,
      :tagging,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutPublicAccessBlockRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         content_md5: "ContentMD5",
    #         public_access_block_configuration: { # required
    #           block_public_acls: false,
    #           ignore_public_acls: false,
    #           block_public_policy: false,
    #           restrict_public_buckets: false,
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to set.
    #   @return [String]
    #
    # @!attribute [rw] content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #   @return [String]
    #
    # @!attribute [rw] public_access_block_configuration
    #   The `PublicAccessBlock` configuration that you want to apply to this
    #   Amazon S3 bucket. You can enable the configuration options in any
    #   combination. For more information about when Amazon S3 considers a
    #   bucket or object public, see [The Meaning of "Public"][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    #   @return [Types::PublicAccessBlockConfiguration]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutPublicAccessBlockRequest AWS API Documentation
    #
    class PutPublicAccessBlockRequest < Struct.new(
      :bucket,
      :content_md5,
      :public_access_block_configuration,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the configuration for publishing messages to an Amazon
    # Simple Queue Service (Amazon SQS) queue when Amazon S3 detects
    # specified events.
    #
    # @note When making an API call, you may pass QueueConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         queue_arn: "QueueArn", # required
    #         events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         filter: {
    #           key: {
    #             filter_rules: [
    #               {
    #                 name: "prefix", # accepts prefix, suffix
    #                 value: "FilterRuleValue",
    #               },
    #             ],
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] queue_arn
    #   The Amazon Resource Name (ARN) of the Amazon SQS queue to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of bucket events for which to send notifications
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring Event Notifications][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/QueueConfiguration AWS API Documentation
    #
    class QueueConfiguration < Struct.new(
      :id,
      :queue_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # This data type is deprecated. Use [QueueConfiguration][1] for the same
    # purposes. This data type specifies the configuration for publishing
    # messages to an Amazon Simple Queue Service (Amazon SQS) queue when
    # Amazon S3 detects specified events.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_QueueConfiguration.html
    #
    # @note When making an API call, you may pass QueueConfigurationDeprecated
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         queue: "QueueArn",
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] event
    #   The bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of bucket events for which to send notifications
    #   @return [Array<String>]
    #
    # @!attribute [rw] queue
    #   The Amazon Resource Name (ARN) of the Amazon SQS queue to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/QueueConfigurationDeprecated AWS API Documentation
    #
    class QueueConfigurationDeprecated < Struct.new(
      :id,
      :event,
      :events,
      :queue)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container for the records event.
    #
    # @!attribute [rw] payload
    #   The byte array of partial, one or more result records.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RecordsEvent AWS API Documentation
    #
    class RecordsEvent < Struct.new(
      :payload,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies how requests are redirected. In the event of an error, you
    # can specify a different error code to return.
    #
    # @note When making an API call, you may pass Redirect
    #   data as a hash:
    #
    #       {
    #         host_name: "HostName",
    #         http_redirect_code: "HttpRedirectCode",
    #         protocol: "http", # accepts http, https
    #         replace_key_prefix_with: "ReplaceKeyPrefixWith",
    #         replace_key_with: "ReplaceKeyWith",
    #       }
    #
    # @!attribute [rw] host_name
    #   The host name to use in the redirect request.
    #   @return [String]
    #
    # @!attribute [rw] http_redirect_code
    #   The HTTP redirect code to use on the response. Not required if one
    #   of the siblings is present.
    #   @return [String]
    #
    # @!attribute [rw] protocol
    #   Protocol to use when redirecting requests. The default is the
    #   protocol that is used in the original request.
    #   @return [String]
    #
    # @!attribute [rw] replace_key_prefix_with
    #   The object key prefix to use in the redirect request. For example,
    #   to redirect requests for all pages with prefix `docs/` (objects in
    #   the `docs/` folder) to `documents/`, you can set a condition block
    #   with `KeyPrefixEquals` set to `docs/` and in the Redirect set
    #   `ReplaceKeyPrefixWith` to `/documents`. Not required if one of the
    #   siblings is present. Can be present only if `ReplaceKeyWith` is not
    #   provided.
    #   @return [String]
    #
    # @!attribute [rw] replace_key_with
    #   The specific object key to use in the redirect request. For example,
    #   redirect request to `error.html`. Not required if one of the
    #   siblings is present. Can be present only if `ReplaceKeyPrefixWith`
    #   is not provided.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Redirect AWS API Documentation
    #
    class Redirect < Struct.new(
      :host_name,
      :http_redirect_code,
      :protocol,
      :replace_key_prefix_with,
      :replace_key_with)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the redirect behavior of all requests to a website endpoint
    # of an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass RedirectAllRequestsTo
    #   data as a hash:
    #
    #       {
    #         host_name: "HostName", # required
    #         protocol: "http", # accepts http, https
    #       }
    #
    # @!attribute [rw] host_name
    #   Name of the host where requests are redirected.
    #   @return [String]
    #
    # @!attribute [rw] protocol
    #   Protocol to use when redirecting requests. The default is the
    #   protocol that is used in the original request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RedirectAllRequestsTo AWS API Documentation
    #
    class RedirectAllRequestsTo < Struct.new(
      :host_name,
      :protocol)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for replication rules. You can add up to 1,000 rules. The
    # maximum size of a replication configuration is 2 MB.
    #
    # @note When making an API call, you may pass ReplicationConfiguration
    #   data as a hash:
    #
    #       {
    #         role: "Role", # required
    #         rules: [ # required
    #           {
    #             id: "ID",
    #             priority: 1,
    #             prefix: "Prefix",
    #             filter: {
    #               prefix: "Prefix",
    #               tag: {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #               and: {
    #                 prefix: "Prefix",
    #                 tags: [
    #                   {
    #                     key: "ObjectKey", # required
    #                     value: "Value", # required
    #                   },
    #                 ],
    #               },
    #             },
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #             source_selection_criteria: {
    #               sse_kms_encrypted_objects: {
    #                 status: "Enabled", # required, accepts Enabled, Disabled
    #               },
    #             },
    #             existing_object_replication: {
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #             },
    #             destination: { # required
    #               bucket: "BucketName", # required
    #               account: "AccountId",
    #               storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #               access_control_translation: {
    #                 owner: "Destination", # required, accepts Destination
    #               },
    #               encryption_configuration: {
    #                 replica_kms_key_id: "ReplicaKmsKeyID",
    #               },
    #               replication_time: {
    #                 status: "Enabled", # required, accepts Enabled, Disabled
    #                 time: { # required
    #                   minutes: 1,
    #                 },
    #               },
    #               metrics: {
    #                 status: "Enabled", # required, accepts Enabled, Disabled
    #                 event_threshold: { # required
    #                   minutes: 1,
    #                 },
    #               },
    #             },
    #             delete_marker_replication: {
    #               status: "Enabled", # accepts Enabled, Disabled
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] role
    #   The Amazon Resource Name (ARN) of the AWS Identity and Access
    #   Management (IAM) role that Amazon S3 assumes when replicating
    #   objects. For more information, see [How to Set Up Replication][1] in
    #   the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-how-setup.html
    #   @return [String]
    #
    # @!attribute [rw] rules
    #   A container for one or more replication rules. A replication
    #   configuration must have at least one rule and can contain a maximum
    #   of 1,000 rules.
    #   @return [Array<Types::ReplicationRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationConfiguration AWS API Documentation
    #
    class ReplicationConfiguration < Struct.new(
      :role,
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies which Amazon S3 objects to replicate and where to store the
    # replicas.
    #
    # @note When making an API call, you may pass ReplicationRule
    #   data as a hash:
    #
    #       {
    #         id: "ID",
    #         priority: 1,
    #         prefix: "Prefix",
    #         filter: {
    #           prefix: "Prefix",
    #           tag: {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #           and: {
    #             prefix: "Prefix",
    #             tags: [
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #         },
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #         source_selection_criteria: {
    #           sse_kms_encrypted_objects: {
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #           },
    #         },
    #         existing_object_replication: {
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #         },
    #         destination: { # required
    #           bucket: "BucketName", # required
    #           account: "AccountId",
    #           storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #           access_control_translation: {
    #             owner: "Destination", # required, accepts Destination
    #           },
    #           encryption_configuration: {
    #             replica_kms_key_id: "ReplicaKmsKeyID",
    #           },
    #           replication_time: {
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #             time: { # required
    #               minutes: 1,
    #             },
    #           },
    #           metrics: {
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #             event_threshold: { # required
    #               minutes: 1,
    #             },
    #           },
    #         },
    #         delete_marker_replication: {
    #           status: "Enabled", # accepts Enabled, Disabled
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   A unique identifier for the rule. The maximum value is 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] priority
    #   The priority associated with the rule. If you specify multiple rules
    #   in a replication configuration, Amazon S3 prioritizes the rules to
    #   prevent conflicts when filtering. If two or more rules identify the
    #   same object based on a specified filter, the rule with higher
    #   priority takes precedence. For example:
    #
    #   * Same object quality prefix-based filter criteria if prefixes you
    #     specified in multiple rules overlap
    #
    #   * Same object qualify tag-based filter criteria specified in
    #     multiple rules
    #
    #   For more information, see [Replication](
    #   https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html) in
    #   the *Amazon Simple Storage Service Developer Guide*.
    #   @return [Integer]
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the object or objects to
    #   which the rule applies. The maximum prefix length is 1,024
    #   characters. To include all objects in a bucket, specify an empty
    #   string.
    #   @return [String]
    #
    # @!attribute [rw] filter
    #   A filter that identifies the subset of objects to which the
    #   replication rule applies. A `Filter` must specify exactly one
    #   `Prefix`, `Tag`, or an `And` child element.
    #   @return [Types::ReplicationRuleFilter]
    #
    # @!attribute [rw] status
    #   Specifies whether the rule is enabled.
    #   @return [String]
    #
    # @!attribute [rw] source_selection_criteria
    #   A container that describes additional filters for identifying the
    #   source objects that you want to replicate. You can choose to enable
    #   or disable the replication of these objects. Currently, Amazon S3
    #   supports only the filter that you can specify for objects created
    #   with server-side encryption using a customer master key (CMK) stored
    #   in AWS Key Management Service (SSE-KMS).
    #   @return [Types::SourceSelectionCriteria]
    #
    # @!attribute [rw] existing_object_replication
    #   @return [Types::ExistingObjectReplication]
    #
    # @!attribute [rw] destination
    #   A container for information about the replication destination and
    #   its configurations including enabling the S3 Replication Time
    #   Control (S3 RTC).
    #   @return [Types::Destination]
    #
    # @!attribute [rw] delete_marker_replication
    #   Specifies whether Amazon S3 replicates the delete markers. If you
    #   specify a `Filter`, you must specify this element. However, in the
    #   latest version of replication configuration (when `Filter` is
    #   specified), Amazon S3 doesn't replicate delete markers. Therefore,
    #   the `DeleteMarkerReplication` element can contain only
    #   &lt;Status&gt;Disabled&lt;/Status&gt;. For an example configuration,
    #   see [Basic Rule Configuration][1].
    #
    #   <note markdown="1"> If you don't specify the `Filter` element, Amazon S3 assumes that
    #   the replication configuration is the earlier version, V1. In the
    #   earlier version, Amazon S3 handled replication of delete markers
    #   differently. For more information, see [Backward Compatibility][2].
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-config-min-rule-config
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations
    #   @return [Types::DeleteMarkerReplication]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRule AWS API Documentation
    #
    class ReplicationRule < Struct.new(
      :id,
      :priority,
      :prefix,
      :filter,
      :status,
      :source_selection_criteria,
      :existing_object_replication,
      :destination,
      :delete_marker_replication)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying rule filters. The filters determine the
    # subset of objects to which the rule applies. This element is required
    # only if you specify more than one filter.
    #
    # For example:
    #
    # * If you specify both a `Prefix` and a `Tag` filter, wrap these
    #   filters in an `And` tag.
    #
    # * If you specify a filter based on multiple tags, wrap the `Tag`
    #   elements in an `And` tag
    #
    # @note When making an API call, you may pass ReplicationRuleAndOperator
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tags: [
    #           {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   An array of tags containing key and value pairs.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRuleAndOperator AWS API Documentation
    #
    class ReplicationRuleAndOperator < Struct.new(
      :prefix,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # A filter that identifies the subset of objects to which the
    # replication rule applies. A `Filter` must specify exactly one
    # `Prefix`, `Tag`, or an `And` child element.
    #
    # @note When making an API call, you may pass ReplicationRuleFilter
    #   data as a hash:
    #
    #       {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       }
    #
    # @!attribute [rw] prefix
    #   An object key name prefix that identifies the subset of objects to
    #   which the rule applies.
    #   @return [String]
    #
    # @!attribute [rw] tag
    #   A container for specifying a tag key and value.
    #
    #   The rule applies only to objects that have the tag in their tag set.
    #   @return [Types::Tag]
    #
    # @!attribute [rw] and
    #   A container for specifying rule filters. The filters determine the
    #   subset of objects to which the rule applies. This element is
    #   required only if you specify more than one filter. For example:
    #
    #   * If you specify both a `Prefix` and a `Tag` filter, wrap these
    #     filters in an `And` tag.
    #
    #   * If you specify a filter based on multiple tags, wrap the `Tag`
    #     elements in an `And` tag.
    #   @return [Types::ReplicationRuleAndOperator]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationRuleFilter AWS API Documentation
    #
    class ReplicationRuleFilter < Struct.new(
      :prefix,
      :tag,
      :and)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying S3 Replication Time Control (S3 RTC) related
    # information, including whether S3 RTC is enabled and the time when all
    # objects and operations on objects must be replicated. Must be
    # specified together with a `Metrics` block.
    #
    # @note When making an API call, you may pass ReplicationTime
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #         time: { # required
    #           minutes: 1,
    #         },
    #       }
    #
    # @!attribute [rw] status
    #   Specifies whether the replication time is enabled.
    #   @return [String]
    #
    # @!attribute [rw] time
    #   A container specifying the time by which replication should be
    #   complete for all objects and operations on objects.
    #   @return [Types::ReplicationTimeValue]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationTime AWS API Documentation
    #
    class ReplicationTime < Struct.new(
      :status,
      :time)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container specifying the time value for S3 Replication Time Control
    # (S3 RTC) and replication metrics `EventThreshold`.
    #
    # @note When making an API call, you may pass ReplicationTimeValue
    #   data as a hash:
    #
    #       {
    #         minutes: 1,
    #       }
    #
    # @!attribute [rw] minutes
    #   Contains an integer specifying time in minutes.
    #
    #   Valid values: 15 minutes.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ReplicationTimeValue AWS API Documentation
    #
    class ReplicationTimeValue < Struct.new(
      :minutes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for Payer.
    #
    # @note When making an API call, you may pass RequestPaymentConfiguration
    #   data as a hash:
    #
    #       {
    #         payer: "Requester", # required, accepts Requester, BucketOwner
    #       }
    #
    # @!attribute [rw] payer
    #   Specifies who pays for the download and request fees.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RequestPaymentConfiguration AWS API Documentation
    #
    class RequestPaymentConfiguration < Struct.new(
      :payer)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for specifying if periodic `QueryProgress` messages should
    # be sent.
    #
    # @note When making an API call, you may pass RequestProgress
    #   data as a hash:
    #
    #       {
    #         enabled: false,
    #       }
    #
    # @!attribute [rw] enabled
    #   Specifies whether periodic QueryProgress frames should be sent.
    #   Valid values: TRUE, FALSE. Default value: FALSE.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RequestProgress AWS API Documentation
    #
    class RequestProgress < Struct.new(
      :enabled)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @!attribute [rw] restore_output_path
    #   Indicates the path in the provided S3 output location where Select
    #   results will be restored to.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreObjectOutput AWS API Documentation
    #
    class RestoreObjectOutput < Struct.new(
      :request_charged,
      :restore_output_path)
      SENSITIVE = []
      include Aws::Structure
    end

    # @note When making an API call, you may pass RestoreObjectRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         version_id: "ObjectVersionId",
    #         restore_request: {
    #           days: 1,
    #           glacier_job_parameters: {
    #             tier: "Standard", # required, accepts Standard, Bulk, Expedited
    #           },
    #           type: "SELECT", # accepts SELECT
    #           tier: "Standard", # accepts Standard, Bulk, Expedited
    #           description: "Description",
    #           select_parameters: {
    #             input_serialization: { # required
    #               csv: {
    #                 file_header_info: "USE", # accepts USE, IGNORE, NONE
    #                 comments: "Comments",
    #                 quote_escape_character: "QuoteEscapeCharacter",
    #                 record_delimiter: "RecordDelimiter",
    #                 field_delimiter: "FieldDelimiter",
    #                 quote_character: "QuoteCharacter",
    #                 allow_quoted_record_delimiter: false,
    #               },
    #               compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #               json: {
    #                 type: "DOCUMENT", # accepts DOCUMENT, LINES
    #               },
    #               parquet: {
    #               },
    #             },
    #             expression_type: "SQL", # required, accepts SQL
    #             expression: "Expression", # required
    #             output_serialization: { # required
    #               csv: {
    #                 quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #                 quote_escape_character: "QuoteEscapeCharacter",
    #                 record_delimiter: "RecordDelimiter",
    #                 field_delimiter: "FieldDelimiter",
    #                 quote_character: "QuoteCharacter",
    #               },
    #               json: {
    #                 record_delimiter: "RecordDelimiter",
    #               },
    #             },
    #           },
    #           output_location: {
    #             s3: {
    #               bucket_name: "BucketName", # required
    #               prefix: "LocationPrefix", # required
    #               encryption: {
    #                 encryption_type: "AES256", # required, accepts AES256, aws:kms
    #                 kms_key_id: "SSEKMSKeyId",
    #                 kms_context: "KMSContext",
    #               },
    #               canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #               access_control_list: [
    #                 {
    #                   grantee: {
    #                     display_name: "DisplayName",
    #                     email_address: "EmailAddress",
    #                     id: "ID",
    #                     type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                     uri: "URI",
    #                   },
    #                   permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #                 },
    #               ],
    #               tagging: {
    #                 tag_set: [ # required
    #                   {
    #                     key: "ObjectKey", # required
    #                     value: "Value", # required
    #                   },
    #                 ],
    #               },
    #               user_metadata: [
    #                 {
    #                   name: "MetadataKey",
    #                   value: "MetadataValue",
    #                 },
    #               ],
    #               storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #             },
    #           },
    #         },
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name or containing the object to restore.
    #
    #   When using this API with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the
    #   form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this operation using an access point through the AWS
    #   SDKs, you provide the access point ARN in place of the bucket name.
    #   For more information about access point ARNs, see [Using Access
    #   Points][1] in the *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the operation was initiated.
    #   @return [String]
    #
    # @!attribute [rw] version_id
    #   VersionId used to reference a specific version of the object.
    #   @return [String]
    #
    # @!attribute [rw] restore_request
    #   Container for restore job parameters.
    #   @return [Types::RestoreRequest]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreObjectRequest AWS API Documentation
    #
    class RestoreObjectRequest < Struct.new(
      :bucket,
      :key,
      :version_id,
      :restore_request,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for restore job parameters.
    #
    # @note When making an API call, you may pass RestoreRequest
    #   data as a hash:
    #
    #       {
    #         days: 1,
    #         glacier_job_parameters: {
    #           tier: "Standard", # required, accepts Standard, Bulk, Expedited
    #         },
    #         type: "SELECT", # accepts SELECT
    #         tier: "Standard", # accepts Standard, Bulk, Expedited
    #         description: "Description",
    #         select_parameters: {
    #           input_serialization: { # required
    #             csv: {
    #               file_header_info: "USE", # accepts USE, IGNORE, NONE
    #               comments: "Comments",
    #               quote_escape_character: "QuoteEscapeCharacter",
    #               record_delimiter: "RecordDelimiter",
    #               field_delimiter: "FieldDelimiter",
    #               quote_character: "QuoteCharacter",
    #               allow_quoted_record_delimiter: false,
    #             },
    #             compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #             json: {
    #               type: "DOCUMENT", # accepts DOCUMENT, LINES
    #             },
    #             parquet: {
    #             },
    #           },
    #           expression_type: "SQL", # required, accepts SQL
    #           expression: "Expression", # required
    #           output_serialization: { # required
    #             csv: {
    #               quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #               quote_escape_character: "QuoteEscapeCharacter",
    #               record_delimiter: "RecordDelimiter",
    #               field_delimiter: "FieldDelimiter",
    #               quote_character: "QuoteCharacter",
    #             },
    #             json: {
    #               record_delimiter: "RecordDelimiter",
    #             },
    #           },
    #         },
    #         output_location: {
    #           s3: {
    #             bucket_name: "BucketName", # required
    #             prefix: "LocationPrefix", # required
    #             encryption: {
    #               encryption_type: "AES256", # required, accepts AES256, aws:kms
    #               kms_key_id: "SSEKMSKeyId",
    #               kms_context: "KMSContext",
    #             },
    #             canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #             access_control_list: [
    #               {
    #                 grantee: {
    #                   display_name: "DisplayName",
    #                   email_address: "EmailAddress",
    #                   id: "ID",
    #                   type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                   uri: "URI",
    #                 },
    #                 permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #               },
    #             ],
    #             tagging: {
    #               tag_set: [ # required
    #                 {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #               ],
    #             },
    #             user_metadata: [
    #               {
    #                 name: "MetadataKey",
    #                 value: "MetadataValue",
    #               },
    #             ],
    #             storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] days
    #   Lifetime of the active copy in days. Do not use with restores that
    #   specify `OutputLocation`.
    #   @return [Integer]
    #
    # @!attribute [rw] glacier_job_parameters
    #   S3 Glacier related parameters pertaining to this job. Do not use
    #   with restores that specify `OutputLocation`.
    #   @return [Types::GlacierJobParameters]
    #
    # @!attribute [rw] type
    #   Type of restore request.
    #   @return [String]
    #
    # @!attribute [rw] tier
    #   S3 Glacier retrieval tier at which the restore will be processed.
    #   @return [String]
    #
    # @!attribute [rw] description
    #   The optional description for the job.
    #   @return [String]
    #
    # @!attribute [rw] select_parameters
    #   Describes the parameters for Select job types.
    #   @return [Types::SelectParameters]
    #
    # @!attribute [rw] output_location
    #   Describes the location where the restore job's output is stored.
    #   @return [Types::OutputLocation]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreRequest AWS API Documentation
    #
    class RestoreRequest < Struct.new(
      :days,
      :glacier_job_parameters,
      :type,
      :tier,
      :description,
      :select_parameters,
      :output_location)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the redirect behavior and when a redirect is applied. For
    # more information about routing rules, see [Configuring advanced
    # conditional redirects][1] in the *Amazon Simple Storage Service
    # Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html#advanced-conditional-redirects
    #
    # @note When making an API call, you may pass RoutingRule
    #   data as a hash:
    #
    #       {
    #         condition: {
    #           http_error_code_returned_equals: "HttpErrorCodeReturnedEquals",
    #           key_prefix_equals: "KeyPrefixEquals",
    #         },
    #         redirect: { # required
    #           host_name: "HostName",
    #           http_redirect_code: "HttpRedirectCode",
    #           protocol: "http", # accepts http, https
    #           replace_key_prefix_with: "ReplaceKeyPrefixWith",
    #           replace_key_with: "ReplaceKeyWith",
    #         },
    #       }
    #
    # @!attribute [rw] condition
    #   A container for describing a condition that must be met for the
    #   specified redirect to apply. For example, 1. If request is for pages
    #   in the `/docs` folder, redirect to the `/documents` folder. 2. If
    #   request results in HTTP error 4xx, redirect request to another host
    #   where you might process the error.
    #   @return [Types::Condition]
    #
    # @!attribute [rw] redirect
    #   Container for redirect information. You can redirect requests to
    #   another host, to another page, or with another protocol. In the
    #   event of an error, you can specify a different error code to return.
    #   @return [Types::Redirect]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RoutingRule AWS API Documentation
    #
    class RoutingRule < Struct.new(
      :condition,
      :redirect)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies lifecycle rules for an Amazon S3 bucket. For more
    # information, see [Put Bucket Lifecycle Configuration][1] in the
    # *Amazon Simple Storage Service API Reference*. For examples, see [Put
    # Bucket Lifecycle Configuration Examples][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html#API_PutBucketLifecycleConfiguration_Examples
    #
    # @note When making an API call, you may pass Rule
    #   data as a hash:
    #
    #       {
    #         expiration: {
    #           date: Time.now,
    #           days: 1,
    #           expired_object_delete_marker: false,
    #         },
    #         id: "ID",
    #         prefix: "Prefix", # required
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #         transition: {
    #           date: Time.now,
    #           days: 1,
    #           storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #         },
    #         noncurrent_version_transition: {
    #           noncurrent_days: 1,
    #           storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #         },
    #         noncurrent_version_expiration: {
    #           noncurrent_days: 1,
    #         },
    #         abort_incomplete_multipart_upload: {
    #           days_after_initiation: 1,
    #         },
    #       }
    #
    # @!attribute [rw] expiration
    #   Specifies the expiration for the lifecycle of the object.
    #   @return [Types::LifecycleExpiration]
    #
    # @!attribute [rw] id
    #   Unique identifier for the rule. The value can't be longer than 255
    #   characters.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   Object key prefix that identifies one or more objects to which this
    #   rule applies.
    #   @return [String]
    #
    # @!attribute [rw] status
    #   If `Enabled`, the rule is currently being applied. If `Disabled`,
    #   the rule is not currently being applied.
    #   @return [String]
    #
    # @!attribute [rw] transition
    #   Specifies when an object transitions to a specified storage class.
    #   For more information about Amazon S3 lifecycle configuration rules,
    #   see [Transitioning Objects Using Amazon S3 Lifecycle][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-transition-general-considerations.html
    #   @return [Types::Transition]
    #
    # @!attribute [rw] noncurrent_version_transition
    #   Container for the transition rule that describes when noncurrent
    #   objects transition to the `STANDARD_IA`, `ONEZONE_IA`,
    #   `INTELLIGENT_TIERING`, `GLACIER`, or `DEEP_ARCHIVE` storage class.
    #   If your bucket is versioning-enabled (or versioning is suspended),
    #   you can set this action to request that Amazon S3 transition
    #   noncurrent object versions to the `STANDARD_IA`, `ONEZONE_IA`,
    #   `INTELLIGENT_TIERING`, `GLACIER`, or `DEEP_ARCHIVE` storage class at
    #   a specific period in the object's lifetime.
    #   @return [Types::NoncurrentVersionTransition]
    #
    # @!attribute [rw] noncurrent_version_expiration
    #   Specifies when noncurrent object versions expire. Upon expiration,
    #   Amazon S3 permanently deletes the noncurrent object versions. You
    #   set this lifecycle configuration action on a bucket that has
    #   versioning enabled (or suspended) to request that Amazon S3 delete
    #   noncurrent object versions at a specific period in the object's
    #   lifetime.
    #   @return [Types::NoncurrentVersionExpiration]
    #
    # @!attribute [rw] abort_incomplete_multipart_upload
    #   Specifies the days since the initiation of an incomplete multipart
    #   upload that Amazon S3 will wait before permanently removing all
    #   parts of the upload. For more information, see [ Aborting Incomplete
    #   Multipart Uploads Using a Bucket Lifecycle Policy][1] in the *Amazon
    #   Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    #   @return [Types::AbortIncompleteMultipartUpload]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Rule AWS API Documentation
    #
    class Rule < Struct.new(
      :expiration,
      :id,
      :prefix,
      :status,
      :transition,
      :noncurrent_version_transition,
      :noncurrent_version_expiration,
      :abort_incomplete_multipart_upload)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for object key name prefix and suffix filtering rules.
    #
    # @note When making an API call, you may pass S3KeyFilter
    #   data as a hash:
    #
    #       {
    #         filter_rules: [
    #           {
    #             name: "prefix", # accepts prefix, suffix
    #             value: "FilterRuleValue",
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] filter_rules
    #   A list of containers for the key-value pair that defines the
    #   criteria for the filter rule.
    #   @return [Array<Types::FilterRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3KeyFilter AWS API Documentation
    #
    class S3KeyFilter < Struct.new(
      :filter_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes an Amazon S3 location that will receive the results of the
    # restore request.
    #
    # @note When making an API call, you may pass S3Location
    #   data as a hash:
    #
    #       {
    #         bucket_name: "BucketName", # required
    #         prefix: "LocationPrefix", # required
    #         encryption: {
    #           encryption_type: "AES256", # required, accepts AES256, aws:kms
    #           kms_key_id: "SSEKMSKeyId",
    #           kms_context: "KMSContext",
    #         },
    #         canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #         access_control_list: [
    #           {
    #             grantee: {
    #               display_name: "DisplayName",
    #               email_address: "EmailAddress",
    #               id: "ID",
    #               type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #               uri: "URI",
    #             },
    #             permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #           },
    #         ],
    #         tagging: {
    #           tag_set: [ # required
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #         user_metadata: [
    #           {
    #             name: "MetadataKey",
    #             value: "MetadataValue",
    #           },
    #         ],
    #         storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
    #       }
    #
    # @!attribute [rw] bucket_name
    #   The name of the bucket where the restore results will be placed.
    #   @return [String]
    #
    # @!attribute [rw] prefix
    #   The prefix that is prepended to the restore results for this
    #   request.
    #   @return [String]
    #
    # @!attribute [rw] encryption
    #   Contains the type of server-side encryption used.
    #   @return [Types::Encryption]
    #
    # @!attribute [rw] canned_acl
    #   The canned ACL to apply to the restore results.
    #   @return [String]
    #
    # @!attribute [rw] access_control_list
    #   A list of grants that control access to the staged results.
    #   @return [Array<Types::Grant>]
    #
    # @!attribute [rw] tagging
    #   The tag-set that is applied to the restore results.
    #   @return [Types::Tagging]
    #
    # @!attribute [rw] user_metadata
    #   A list of metadata to store with the restore results in S3.
    #   @return [Array<Types::MetadataEntry>]
    #
    # @!attribute [rw] storage_class
    #   The class of storage used to store the restore results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/S3Location AWS API Documentation
    #
    class S3Location < Struct.new(
      :bucket_name,
      :prefix,
      :encryption,
      :canned_acl,
      :access_control_list,
      :tagging,
      :user_metadata,
      :storage_class)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the use of SSE-KMS to encrypt delivered inventory reports.
    #
    # @note When making an API call, you may pass SSEKMS
    #   data as a hash:
    #
    #       {
    #         key_id: "SSEKMSKeyId", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   Specifies the ID of the AWS Key Management Service (AWS KMS)
    #   symmetric customer managed customer master key (CMK) to use for
    #   encrypting inventory reports.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SSEKMS AWS API Documentation
    #
    class SSEKMS < Struct.new(
      :key_id)
      SENSITIVE = [:key_id]
      include Aws::Structure
    end

    # Specifies the use of SSE-S3 to encrypt delivered inventory reports.
    #
    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SSES3 AWS API Documentation
    #
    class SSES3 < Aws::EmptyStructure; end

    # Specifies the byte range of the object to get the records from. A
    # record is processed when its first byte is contained by the range.
    # This parameter is optional, but when specified, it must not be empty.
    # See RFC 2616, Section 14.35.1 about how to specify the start and end
    # of the range.
    #
    # @note When making an API call, you may pass ScanRange
    #   data as a hash:
    #
    #       {
    #         start: 1,
    #         end: 1,
    #       }
    #
    # @!attribute [rw] start
    #   Specifies the start of the byte range. This parameter is optional.
    #   Valid values: non-negative integers. The default value is 0. If only
    #   start is supplied, it means scan from that point to the end of the
    #   file.For example; `<scanrange><start>50</start></scanrange>` means
    #   scan from byte 50 until the end of the file.
    #   @return [Integer]
    #
    # @!attribute [rw] end
    #   Specifies the end of the byte range. This parameter is optional.
    #   Valid values: non-negative integers. The default value is one less
    #   than the size of the object being queried. If only the End parameter
    #   is supplied, it is interpreted to mean scan the last N bytes of the
    #   file. For example, `<scanrange><end>50</end></scanrange>` means scan
    #   the last 50 bytes.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ScanRange AWS API Documentation
    #
    class ScanRange < Struct.new(
      :start,
      :end)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] payload
    #   The array of results.
    #   @return [Types::SelectObjectContentEventStream]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentOutput AWS API Documentation
    #
    class SelectObjectContentOutput < Struct.new(
      :payload)
      SENSITIVE = []
      include Aws::Structure
    end

    # Request to filter the contents of an Amazon S3 object based on a
    # simple Structured Query Language (SQL) statement. In the request,
    # along with the SQL expression, you must specify a data serialization
    # format (JSON or CSV) of the object. Amazon S3 uses this to parse
    # object data into records. It returns only records that match the
    # specified SQL expression. You must also specify the data serialization
    # format for the response. For more information, see [S3Select API
    # Documentation][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectSELECTContent.html
    #
    # @note When making an API call, you may pass SelectObjectContentRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         key: "ObjectKey", # required
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         expression: "Expression", # required
    #         expression_type: "SQL", # required, accepts SQL
    #         request_progress: {
    #           enabled: false,
    #         },
    #         input_serialization: { # required
    #           csv: {
    #             file_header_info: "USE", # accepts USE, IGNORE, NONE
    #             comments: "Comments",
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #             allow_quoted_record_delimiter: false,
    #           },
    #           compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #           json: {
    #             type: "DOCUMENT", # accepts DOCUMENT, LINES
    #           },
    #           parquet: {
    #           },
    #         },
    #         output_serialization: { # required
    #           csv: {
    #             quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #           },
    #           json: {
    #             record_delimiter: "RecordDelimiter",
    #           },
    #         },
    #         scan_range: {
    #           start: 1,
    #           end: 1,
    #         },
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The S3 bucket.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   The object key.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   The SSE Algorithm used to encrypt the object. For more information,
    #   see [Server-Side Encryption (Using Customer-Provided Encryption
    #   Keys][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   The SSE Customer Key. For more information, see [Server-Side
    #   Encryption (Using Customer-Provided Encryption Keys][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   The SSE Customer Key MD5. For more information, see [Server-Side
    #   Encryption (Using Customer-Provided Encryption Keys][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #   @return [String]
    #
    # @!attribute [rw] expression
    #   The expression that is used to query the object.
    #   @return [String]
    #
    # @!attribute [rw] expression_type
    #   The type of the provided expression (for example, SQL).
    #   @return [String]
    #
    # @!attribute [rw] request_progress
    #   Specifies if periodic request progress information should be
    #   enabled.
    #   @return [Types::RequestProgress]
    #
    # @!attribute [rw] input_serialization
    #   Describes the format of the data in the object that is being
    #   queried.
    #   @return [Types::InputSerialization]
    #
    # @!attribute [rw] output_serialization
    #   Describes the format of the data that you want Amazon S3 to return
    #   in response.
    #   @return [Types::OutputSerialization]
    #
    # @!attribute [rw] scan_range
    #   Specifies the byte range of the object to get the records from. A
    #   record is processed when its first byte is contained by the range.
    #   This parameter is optional, but when specified, it must not be
    #   empty. See RFC 2616, Section 14.35.1 about how to specify the start
    #   and end of the range.
    #
    #   `ScanRange`may be used in the following ways:
    #
    #   * `<scanrange><start>50</start><end>100</end></scanrange>` - process
    #     only the records starting between the bytes 50 and 100 (inclusive,
    #     counting from zero)
    #
    #   * `<scanrange><start>50</start></scanrange>` - process only the
    #     records starting after the byte 50
    #
    #   * `<scanrange><end>50</end></scanrange>` - process only the records
    #     within the last 50 bytes of the file.
    #   @return [Types::ScanRange]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentRequest AWS API Documentation
    #
    class SelectObjectContentRequest < Struct.new(
      :bucket,
      :key,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :expression,
      :expression_type,
      :request_progress,
      :input_serialization,
      :output_serialization,
      :scan_range,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Describes the parameters for Select job types.
    #
    # @note When making an API call, you may pass SelectParameters
    #   data as a hash:
    #
    #       {
    #         input_serialization: { # required
    #           csv: {
    #             file_header_info: "USE", # accepts USE, IGNORE, NONE
    #             comments: "Comments",
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #             allow_quoted_record_delimiter: false,
    #           },
    #           compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #           json: {
    #             type: "DOCUMENT", # accepts DOCUMENT, LINES
    #           },
    #           parquet: {
    #           },
    #         },
    #         expression_type: "SQL", # required, accepts SQL
    #         expression: "Expression", # required
    #         output_serialization: { # required
    #           csv: {
    #             quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #           },
    #           json: {
    #             record_delimiter: "RecordDelimiter",
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] input_serialization
    #   Describes the serialization format of the object.
    #   @return [Types::InputSerialization]
    #
    # @!attribute [rw] expression_type
    #   The type of the provided expression (for example, SQL).
    #   @return [String]
    #
    # @!attribute [rw] expression
    #   The expression that is used to query the object.
    #   @return [String]
    #
    # @!attribute [rw] output_serialization
    #   Describes how the results of the Select job are serialized.
    #   @return [Types::OutputSerialization]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectParameters AWS API Documentation
    #
    class SelectParameters < Struct.new(
      :input_serialization,
      :expression_type,
      :expression,
      :output_serialization)
      SENSITIVE = []
      include Aws::Structure
    end

    # Describes the default server-side encryption to apply to new objects
    # in the bucket. If a PUT Object request doesn't specify any
    # server-side encryption, this default encryption will be applied. For
    # more information, see [PUT Bucket encryption][1] in the *Amazon Simple
    # Storage Service API Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTencryption.html
    #
    # @note When making an API call, you may pass ServerSideEncryptionByDefault
    #   data as a hash:
    #
    #       {
    #         sse_algorithm: "AES256", # required, accepts AES256, aws:kms
    #         kms_master_key_id: "SSEKMSKeyId",
    #       }
    #
    # @!attribute [rw] sse_algorithm
    #   Server-side encryption algorithm to use for the default encryption.
    #   @return [String]
    #
    # @!attribute [rw] kms_master_key_id
    #   AWS Key Management Service (KMS) customer master key ID to use for
    #   the default encryption. This parameter is allowed if and only if
    #   `SSEAlgorithm` is set to `aws:kms`.
    #
    #   You can specify the key ID or the Amazon Resource Name (ARN) of the
    #   CMK. However, if you are using encryption with cross-account
    #   operations, you must use a fully qualified CMK ARN. For more
    #   information, see [Using encryption for cross-account operations][1].
    #
    #   **For example:**
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   Amazon S3 only supports symmetric CMKs and not asymmetric CMKs. For
    #   more information, see [Using Symmetric and Asymmetric Keys][2] in
    #   the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html#bucket-encryption-update-bucket-policy
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionByDefault AWS API Documentation
    #
    class ServerSideEncryptionByDefault < Struct.new(
      :sse_algorithm,
      :kms_master_key_id)
      SENSITIVE = [:kms_master_key_id]
      include Aws::Structure
    end

    # Specifies the default server-side-encryption configuration.
    #
    # @note When making an API call, you may pass ServerSideEncryptionConfiguration
    #   data as a hash:
    #
    #       {
    #         rules: [ # required
    #           {
    #             apply_server_side_encryption_by_default: {
    #               sse_algorithm: "AES256", # required, accepts AES256, aws:kms
    #               kms_master_key_id: "SSEKMSKeyId",
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] rules
    #   Container for information about a particular server-side encryption
    #   configuration rule.
    #   @return [Array<Types::ServerSideEncryptionRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionConfiguration AWS API Documentation
    #
    class ServerSideEncryptionConfiguration < Struct.new(
      :rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies the default server-side encryption configuration.
    #
    # @note When making an API call, you may pass ServerSideEncryptionRule
    #   data as a hash:
    #
    #       {
    #         apply_server_side_encryption_by_default: {
    #           sse_algorithm: "AES256", # required, accepts AES256, aws:kms
    #           kms_master_key_id: "SSEKMSKeyId",
    #         },
    #       }
    #
    # @!attribute [rw] apply_server_side_encryption_by_default
    #   Specifies the default server-side encryption to apply to new objects
    #   in the bucket. If a PUT Object request doesn't specify any
    #   server-side encryption, this default encryption will be applied.
    #   @return [Types::ServerSideEncryptionByDefault]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ServerSideEncryptionRule AWS API Documentation
    #
    class ServerSideEncryptionRule < Struct.new(
      :apply_server_side_encryption_by_default)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container that describes additional filters for identifying the
    # source objects that you want to replicate. You can choose to enable or
    # disable the replication of these objects. Currently, Amazon S3
    # supports only the filter that you can specify for objects created with
    # server-side encryption using a customer master key (CMK) stored in AWS
    # Key Management Service (SSE-KMS).
    #
    # @note When making an API call, you may pass SourceSelectionCriteria
    #   data as a hash:
    #
    #       {
    #         sse_kms_encrypted_objects: {
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #         },
    #       }
    #
    # @!attribute [rw] sse_kms_encrypted_objects
    #   A container for filter information for the selection of Amazon S3
    #   objects encrypted with AWS KMS. If you include
    #   `SourceSelectionCriteria` in the replication configuration, this
    #   element is required.
    #   @return [Types::SseKmsEncryptedObjects]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SourceSelectionCriteria AWS API Documentation
    #
    class SourceSelectionCriteria < Struct.new(
      :sse_kms_encrypted_objects)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for filter information for the selection of S3 objects
    # encrypted with AWS KMS.
    #
    # @note When making an API call, you may pass SseKmsEncryptedObjects
    #   data as a hash:
    #
    #       {
    #         status: "Enabled", # required, accepts Enabled, Disabled
    #       }
    #
    # @!attribute [rw] status
    #   Specifies whether Amazon S3 replicates objects created with
    #   server-side encryption using a customer master key (CMK) stored in
    #   AWS Key Management Service.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SseKmsEncryptedObjects AWS API Documentation
    #
    class SseKmsEncryptedObjects < Struct.new(
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the stats details.
    #
    # @!attribute [rw] bytes_scanned
    #   The total number of object bytes scanned.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_processed
    #   The total number of uncompressed object bytes processed.
    #   @return [Integer]
    #
    # @!attribute [rw] bytes_returned
    #   The total number of bytes of records payload data returned.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Stats AWS API Documentation
    #
    class Stats < Struct.new(
      :bytes_scanned,
      :bytes_processed,
      :bytes_returned)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for the Stats Event.
    #
    # @!attribute [rw] details
    #   The Stats event details.
    #   @return [Types::Stats]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StatsEvent AWS API Documentation
    #
    class StatsEvent < Struct.new(
      :details,
      :event_type)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies data related to access patterns to be collected and made
    # available to analyze the tradeoffs between different storage classes
    # for an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass StorageClassAnalysis
    #   data as a hash:
    #
    #       {
    #         data_export: {
    #           output_schema_version: "V_1", # required, accepts V_1
    #           destination: { # required
    #             s3_bucket_destination: { # required
    #               format: "CSV", # required, accepts CSV
    #               bucket_account_id: "AccountId",
    #               bucket: "BucketName", # required
    #               prefix: "Prefix",
    #             },
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] data_export
    #   Specifies how data related to the storage class analysis for an
    #   Amazon S3 bucket should be exported.
    #   @return [Types::StorageClassAnalysisDataExport]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StorageClassAnalysis AWS API Documentation
    #
    class StorageClassAnalysis < Struct.new(
      :data_export)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for data related to the storage class analysis for an Amazon
    # S3 bucket for export.
    #
    # @note When making an API call, you may pass StorageClassAnalysisDataExport
    #   data as a hash:
    #
    #       {
    #         output_schema_version: "V_1", # required, accepts V_1
    #         destination: { # required
    #           s3_bucket_destination: { # required
    #             format: "CSV", # required, accepts CSV
    #             bucket_account_id: "AccountId",
    #             bucket: "BucketName", # required
    #             prefix: "Prefix",
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] output_schema_version
    #   The version of the output schema to use when exporting data. Must be
    #   `V_1`.
    #   @return [String]
    #
    # @!attribute [rw] destination
    #   The place to store the data for an analysis.
    #   @return [Types::AnalyticsExportDestination]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/StorageClassAnalysisDataExport AWS API Documentation
    #
    class StorageClassAnalysisDataExport < Struct.new(
      :output_schema_version,
      :destination)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container of a key value name pair.
    #
    # @note When making an API call, you may pass Tag
    #   data as a hash:
    #
    #       {
    #         key: "ObjectKey", # required
    #         value: "Value", # required
    #       }
    #
    # @!attribute [rw] key
    #   Name of the object key.
    #   @return [String]
    #
    # @!attribute [rw] value
    #   Value of the tag.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Tag AWS API Documentation
    #
    class Tag < Struct.new(
      :key,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for `TagSet` elements.
    #
    # @note When making an API call, you may pass Tagging
    #   data as a hash:
    #
    #       {
    #         tag_set: [ # required
    #           {
    #             key: "ObjectKey", # required
    #             value: "Value", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] tag_set
    #   A collection for a set of tags
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Tagging AWS API Documentation
    #
    class Tagging < Struct.new(
      :tag_set)
      SENSITIVE = []
      include Aws::Structure
    end

    # Container for granting information.
    #
    # @note When making an API call, you may pass TargetGrant
    #   data as a hash:
    #
    #       {
    #         grantee: {
    #           display_name: "DisplayName",
    #           email_address: "EmailAddress",
    #           id: "ID",
    #           type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #           uri: "URI",
    #         },
    #         permission: "FULL_CONTROL", # accepts FULL_CONTROL, READ, WRITE
    #       }
    #
    # @!attribute [rw] grantee
    #   Container for the person being granted permissions.
    #   @return [Types::Grantee]
    #
    # @!attribute [rw] permission
    #   Logging permissions assigned to the Grantee for the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TargetGrant AWS API Documentation
    #
    class TargetGrant < Struct.new(
      :grantee,
      :permission)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for publication of
    # messages to an Amazon Simple Notification Service (Amazon SNS) topic
    # when Amazon S3 detects specified events.
    #
    # @note When making an API call, you may pass TopicConfiguration
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         topic_arn: "TopicArn", # required
    #         events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         filter: {
    #           key: {
    #             filter_rules: [
    #               {
    #                 name: "prefix", # accepts prefix, suffix
    #                 value: "FilterRuleValue",
    #               },
    #             ],
    #           },
    #         },
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] topic_arn
    #   The Amazon Resource Name (ARN) of the Amazon SNS topic to which
    #   Amazon S3 publishes a message when it detects events of the
    #   specified type.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   The Amazon S3 bucket event about which to send notifications. For
    #   more information, see [Supported Event Types][1] in the *Amazon
    #   Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Array<String>]
    #
    # @!attribute [rw] filter
    #   Specifies object key name filtering rules. For information about key
    #   name filtering, see [Configuring Event Notifications][1] in the
    #   *Amazon Simple Storage Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    #   @return [Types::NotificationConfigurationFilter]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TopicConfiguration AWS API Documentation
    #
    class TopicConfiguration < Struct.new(
      :id,
      :topic_arn,
      :events,
      :filter)
      SENSITIVE = []
      include Aws::Structure
    end

    # A container for specifying the configuration for publication of
    # messages to an Amazon Simple Notification Service (Amazon SNS) topic
    # when Amazon S3 detects specified events. This data type is deprecated.
    # Use [TopicConfiguration][1] instead.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_TopicConfiguration.html
    #
    # @note When making an API call, you may pass TopicConfigurationDeprecated
    #   data as a hash:
    #
    #       {
    #         id: "NotificationId",
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold
    #         topic: "TopicArn",
    #       }
    #
    # @!attribute [rw] id
    #   An optional unique identifier for configurations in a notification
    #   configuration. If you don't provide one, Amazon S3 will assign an
    #   ID.
    #   @return [String]
    #
    # @!attribute [rw] events
    #   A collection of events related to objects
    #   @return [Array<String>]
    #
    # @!attribute [rw] event
    #   Bucket event for which to send notifications.
    #   @return [String]
    #
    # @!attribute [rw] topic
    #   Amazon SNS topic to which Amazon S3 will publish a message to report
    #   the specified events for the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/TopicConfigurationDeprecated AWS API Documentation
    #
    class TopicConfigurationDeprecated < Struct.new(
      :id,
      :events,
      :event,
      :topic)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies when an object transitions to a specified storage class. For
    # more information about Amazon S3 lifecycle configuration rules, see
    # [Transitioning Objects Using Amazon S3 Lifecycle][1] in the *Amazon
    # Simple Storage Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-transition-general-considerations.html
    #
    # @note When making an API call, you may pass Transition
    #   data as a hash:
    #
    #       {
    #         date: Time.now,
    #         days: 1,
    #         storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE
    #       }
    #
    # @!attribute [rw] date
    #   Indicates when objects are transitioned to the specified storage
    #   class. The date value must be in ISO 8601 format. The time is always
    #   midnight UTC.
    #   @return [Time]
    #
    # @!attribute [rw] days
    #   Indicates the number of days after creation when objects are
    #   transitioned to the specified storage class. The value must be a
    #   positive integer.
    #   @return [Integer]
    #
    # @!attribute [rw] storage_class
    #   The storage class to which you want the object to transition.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/Transition AWS API Documentation
    #
    class Transition < Struct.new(
      :date,
      :days,
      :storage_class)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] copy_source_version_id
    #   The version of the source object that was copied, if you have
    #   enabled versioning on the source bucket.
    #   @return [String]
    #
    # @!attribute [rw] copy_part_result
    #   Container for all response elements.
    #   @return [Types::CopyPartResult]
    #
    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) that was
    #   used for the object.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartCopyOutput AWS API Documentation
    #
    class UploadPartCopyOutput < Struct.new(
      :copy_source_version_id,
      :copy_part_result,
      :server_side_encryption,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @note When making an API call, you may pass UploadPartCopyRequest
    #   data as a hash:
    #
    #       {
    #         bucket: "BucketName", # required
    #         copy_source: "CopySource", # required
    #         copy_source_if_match: "CopySourceIfMatch",
    #         copy_source_if_modified_since: Time.now,
    #         copy_source_if_none_match: "CopySourceIfNoneMatch",
    #         copy_source_if_unmodified_since: Time.now,
    #         copy_source_range: "CopySourceRange",
    #         key: "ObjectKey", # required
    #         part_number: 1, # required
    #         upload_id: "MultipartUploadId", # required
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         copy_source_sse_customer_algorithm: "CopySourceSSECustomerAlgorithm",
    #         copy_source_sse_customer_key: "CopySourceSSECustomerKey",
    #         copy_source_sse_customer_key_md5: "CopySourceSSECustomerKeyMD5",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #         expected_source_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] bucket
    #   The bucket name.
    #   @return [String]
    #
    # @!attribute [rw] copy_source
    #   Specifies the source object for the copy operation. You specify the
    #   value in one of two formats, depending on whether you want to access
    #   the source object through an [access point][1]\:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and key of the source object, separated by a
    #     slash (/). For example, to copy the object `reports/january.pdf`
    #     from the bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be URL
    #     encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through the
    #     access point `my-access-point` owned by account `123456789012` in
    #     Region `us-west-2`, use the URL encoding of
    #     `arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf`.
    #     The value must be URL encoded.
    #
    #     <note markdown="1"> Amazon S3 supports copy operations using access points only when
    #     the source and destination buckets are in the same AWS Region.
    #
    #      </note>
    #
    #   To copy a specific version of an object, append
    #   `?versionId=<version-id>` to the value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified
    #   tag.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #   @return [Time]
    #
    # @!attribute [rw] copy_source_range
    #   The range of bytes to copy from the source object. The range value
    #   must use the form bytes=first-last, where the first and last are the
    #   zero-based byte offsets to copy. For example, bytes=0-9 indicates
    #   that you want to copy the first 10 bytes of the source. You can copy
    #   a range only if the source object is greater than 5 MB.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of part being copied. This is a positive integer between
    #   1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose part is being
    #   copied.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header. This must
    #   be the same encryption key specified in the initiate multipart
    #   upload request.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object
    #   (for example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   to decrypt the source object. The encryption key provided in this
    #   header must be one that was used when the source object was created.
    #   @return [String]
    #
    # @!attribute [rw] copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected destination bucket owner. If the
    #   destination bucket is owned by a different account, the request will
    #   fail with an HTTP `403 (Access Denied)` error.
    #   @return [String]
    #
    # @!attribute [rw] expected_source_bucket_owner
    #   The account id of the expected source bucket owner. If the source
    #   bucket is owned by a different account, the request will fail with
    #   an HTTP `403 (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartCopyRequest AWS API Documentation
    #
    class UploadPartCopyRequest < Struct.new(
      :bucket,
      :copy_source,
      :copy_source_if_match,
      :copy_source_if_modified_since,
      :copy_source_if_none_match,
      :copy_source_if_unmodified_since,
      :copy_source_range,
      :key,
      :part_number,
      :upload_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :copy_source_sse_customer_algorithm,
      :copy_source_sse_customer_key,
      :copy_source_sse_customer_key_md5,
      :request_payer,
      :expected_bucket_owner,
      :expected_source_bucket_owner)
      SENSITIVE = [:sse_customer_key, :copy_source_sse_customer_key]
      include Aws::Structure
    end

    # @!attribute [rw] server_side_encryption
    #   The server-side encryption algorithm used when storing this object
    #   in Amazon S3 (for example, AES256, aws:kms).
    #   @return [String]
    #
    # @!attribute [rw] etag
    #   Entity tag for the uploaded object.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header confirming the
    #   encryption algorithm used.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   If server-side encryption with a customer-provided encryption key
    #   was requested, the response will include this header to provide
    #   round-trip message integrity verification of the customer-provided
    #   encryption key.
    #   @return [String]
    #
    # @!attribute [rw] ssekms_key_id
    #   If present, specifies the ID of the AWS Key Management Service (AWS
    #   KMS) symmetric customer managed customer master key (CMK) was used
    #   for the object.
    #   @return [String]
    #
    # @!attribute [rw] request_charged
    #   If present, indicates that the requester was successfully charged
    #   for the request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartOutput AWS API Documentation
    #
    class UploadPartOutput < Struct.new(
      :server_side_encryption,
      :etag,
      :sse_customer_algorithm,
      :sse_customer_key_md5,
      :ssekms_key_id,
      :request_charged)
      SENSITIVE = [:ssekms_key_id]
      include Aws::Structure
    end

    # @note When making an API call, you may pass UploadPartRequest
    #   data as a hash:
    #
    #       {
    #         body: source_file,
    #         bucket: "BucketName", # required
    #         content_length: 1,
    #         content_md5: "ContentMD5",
    #         key: "ObjectKey", # required
    #         part_number: 1, # required
    #         upload_id: "MultipartUploadId", # required
    #         sse_customer_algorithm: "SSECustomerAlgorithm",
    #         sse_customer_key: "SSECustomerKey",
    #         sse_customer_key_md5: "SSECustomerKeyMD5",
    #         request_payer: "requester", # accepts requester
    #         expected_bucket_owner: "AccountId",
    #       }
    #
    # @!attribute [rw] body
    #   Object data.
    #   @return [IO]
    #
    # @!attribute [rw] bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically.
    #   @return [Integer]
    #
    # @!attribute [rw] content_md5
    #   The base64-encoded 128-bit MD5 digest of the part data. This
    #   parameter is auto-populated when using the command from the CLI.
    #   This parameter is required if object lock parameters are specified.
    #   @return [String]
    #
    # @!attribute [rw] key
    #   Object key for which the multipart upload was initiated.
    #   @return [String]
    #
    # @!attribute [rw] part_number
    #   Part number of part being uploaded. This is a positive integer
    #   between 1 and 10,000.
    #   @return [Integer]
    #
    # @!attribute [rw] upload_id
    #   Upload ID identifying the multipart upload whose part is being
    #   uploaded.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use
    #   in encrypting data. This value is used to store the object and then
    #   it is discarded; Amazon S3 does not store the encryption key. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm header`. This must
    #   be the same encryption key specified in the initiate multipart
    #   upload request.
    #   @return [String]
    #
    # @!attribute [rw] sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check
    #   to ensure that the encryption key was transmitted without error.
    #   @return [String]
    #
    # @!attribute [rw] request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from requester
    #   pays buckets, see [Downloading Objects in Requestor Pays Buckets][1]
    #   in the *Amazon S3 Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #   @return [String]
    #
    # @!attribute [rw] expected_bucket_owner
    #   The account id of the expected bucket owner. If the bucket is owned
    #   by a different account, the request will fail with an HTTP `403
    #   (Access Denied)` error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartRequest AWS API Documentation
    #
    class UploadPartRequest < Struct.new(
      :body,
      :bucket,
      :content_length,
      :content_md5,
      :key,
      :part_number,
      :upload_id,
      :sse_customer_algorithm,
      :sse_customer_key,
      :sse_customer_key_md5,
      :request_payer,
      :expected_bucket_owner)
      SENSITIVE = [:sse_customer_key]
      include Aws::Structure
    end

    # Describes the versioning state of an Amazon S3 bucket. For more
    # information, see [PUT Bucket versioning][1] in the *Amazon Simple
    # Storage Service API Reference*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
    #
    # @note When making an API call, you may pass VersioningConfiguration
    #   data as a hash:
    #
    #       {
    #         mfa_delete: "Enabled", # accepts Enabled, Disabled
    #         status: "Enabled", # accepts Enabled, Suspended
    #       }
    #
    # @!attribute [rw] mfa_delete
    #   Specifies whether MFA delete is enabled in the bucket versioning
    #   configuration. This element is only returned if the bucket has been
    #   configured with MFA delete. If the bucket has never been so
    #   configured, this element is not returned.
    #   @return [String]
    #
    # @!attribute [rw] status
    #   The versioning state of the bucket.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/VersioningConfiguration AWS API Documentation
    #
    class VersioningConfiguration < Struct.new(
      :mfa_delete,
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Specifies website configuration parameters for an Amazon S3 bucket.
    #
    # @note When making an API call, you may pass WebsiteConfiguration
    #   data as a hash:
    #
    #       {
    #         error_document: {
    #           key: "ObjectKey", # required
    #         },
    #         index_document: {
    #           suffix: "Suffix", # required
    #         },
    #         redirect_all_requests_to: {
    #           host_name: "HostName", # required
    #           protocol: "http", # accepts http, https
    #         },
    #         routing_rules: [
    #           {
    #             condition: {
    #               http_error_code_returned_equals: "HttpErrorCodeReturnedEquals",
    #               key_prefix_equals: "KeyPrefixEquals",
    #             },
    #             redirect: { # required
    #               host_name: "HostName",
    #               http_redirect_code: "HttpRedirectCode",
    #               protocol: "http", # accepts http, https
    #               replace_key_prefix_with: "ReplaceKeyPrefixWith",
    #               replace_key_with: "ReplaceKeyWith",
    #             },
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] error_document
    #   The name of the error document for the website.
    #   @return [Types::ErrorDocument]
    #
    # @!attribute [rw] index_document
    #   The name of the index document for the website.
    #   @return [Types::IndexDocument]
    #
    # @!attribute [rw] redirect_all_requests_to
    #   The redirect behavior for every request to this bucket's website
    #   endpoint.
    #
    #   If you specify this property, you can't specify any other property.
    #   @return [Types::RedirectAllRequestsTo]
    #
    # @!attribute [rw] routing_rules
    #   Rules that define when a redirect is applied and the redirect
    #   behavior.
    #   @return [Array<Types::RoutingRule>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/WebsiteConfiguration AWS API Documentation
    #
    class WebsiteConfiguration < Struct.new(
      :error_document,
      :index_document,
      :redirect_all_requests_to,
      :routing_rules)
      SENSITIVE = []
      include Aws::Structure
    end

    # The container for selecting objects from a content event stream.
    #
    # EventStream is an Enumerator of Events.
    #  #event_types #=> Array, returns all modeled event types in the stream
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContentEventStream AWS API Documentation
    #
    class SelectObjectContentEventStream < Enumerator

      def event_types
        [
          :records,
          :stats,
          :progress,
          :cont,
          :end
        ]
      end

    end

  end
end
