require 'active_model/validations/date_validator'
require 'active_support/i18n'
require 'date_validator/engine' if defined?(Rails)

# A simple date validator for Rails 3+.
#
# @example
#    validates :expiration_date,
#              date: { after: Proc.new { Time.now },
#                      before: Proc.new { Time.now + 1.year } }
#    # Using Proc.new prevents production cache issues
#
module DateValidator
end
