# frozen_string_literal: true

module TestManagement
  module TestCases
    # Applies the same (already filtered) attributes to many cases. Empty /
    # "no change" keys must be stripped by the caller before #call.
    class BulkUpdateService
      def initialize(user:, test_cases:)
        @user = user
        @test_cases = test_cases
      end

      def call(attributes)
        attributes = attributes.to_h.with_indifferent_access
        return ServiceResult.success(result: test_cases) if attributes.empty?

        failures = []
        test_cases.each do |test_case|
          call = UpdateService.new(user:, model: test_case).call(attributes.deep_dup)
          failures << call unless call.success?
        end

        if failures.empty?
          ServiceResult.success(result: test_cases)
        else
          result = ServiceResult.failure(result: test_cases)
          failures.each do |failed|
            failed.errors.full_messages.each do |message|
              result.errors.add(:base, "#{failed.result.formatted_id}: #{message}")
            end
          end
          result
        end
      end

      private

      attr_reader :user, :test_cases
    end
  end
end
