require 'roar/decorator'

module API
  module V3
    module WorkPackages
      class WorkPackageSumsRepresenter < ::API::Decorators::Single
        def initialize(sums)
          # breaking inheritance law here
          super(sums, current_user: nil)
        end

        def self.create_class(schema)
          injector_class = ::API::V3::Utilities::CustomFieldSumInjector
          injector_class.create_value_representer(schema,
                                                  self)
        end

        def self.create(sums)
          create_class(Schema::WorkPackageSumsSchema.new).new(sums)
        end

        property :estimated_time,
                 exec_context: :decorator,
                 getter: -> (*) {
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 },
                 if: -> (*) {
                   ::Setting.work_package_list_summable_columns.include?('estimated_hours')
                 }
      end
    end
  end
end
