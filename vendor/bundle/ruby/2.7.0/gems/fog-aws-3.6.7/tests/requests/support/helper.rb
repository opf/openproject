class AWS
  module Support
    module Formats
      TRUSTED_ADVISOR_CHECK_FORMAT = {
        'id'          => String,
        'name'        => String,
        'description' => String,
        'metadata'    => Array,
        'category'    => String,
      }

      FLAGGED_RESOURCE = {
        'isSuppressed' => Fog::Boolean,
        'metadata'     => Array,
        'region'       => String,
        'resourceId'   => String,
        'status'       => String
      }

      TRUSTED_ADVISOR_CHECK_RESULT_FORMAT = {
        'categorySpecificSummary' => Hash,
        'checkId'                 => String,
        'flaggedResources'        => [FLAGGED_RESOURCE],
        'resourcesSummary'        => {
          'resourcesFlagged'    => Integer,
          'resourcesIgnored'    => Integer,
          'resourcesProcessed'  => Integer,
          'resourcesSuppressed' => Integer
        },
        'status'                  => String,
        'timestamp'               => String
      }

      DESCRIBE_TRUSTED_ADVISOR_CHECKS = {
        'checks' => [TRUSTED_ADVISOR_CHECK_FORMAT]
      }

      DESCRIBE_TRUSTED_ADVISOR_CHECK_RESULT = {
        'result' => TRUSTED_ADVISOR_CHECK_RESULT_FORMAT
      }
    end
  end
end
