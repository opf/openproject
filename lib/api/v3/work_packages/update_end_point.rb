module API
  module V3
    module WorkPackages
      class UpdateEndPoint < API::V3::Utilities::DefaultUpdate
        def present_success(current_user, call)
          call.result.reload

          super
        end

        def present_error(call)
          errors = call.errors
          errors = merge_dependent_errors call if errors.empty?

          api_errors = [::API::Errors::ErrorBase.create_and_merge_errors(errors)]

          fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
        end

        private

        def merge_dependent_errors(call)
          errors = ActiveModel::Errors.new call.work_package

          call.dependent_results.each do |dr|
            dr.errors.keys.each do |field|
              dr.errors.symbols_and_messages_for(field).each do |symbol, full_message, _|
                errors.add :base, symbol, message: dependent_error_message(result, full_message)
              end
            end
          end

          errors
        end

        def dependent_error_message(result, full_message)
          I18n.t(
            :error_dependent_work_package,
            related_id: result.id,
            related_subject: result.subject,
            error: full_message
          )
        end
      end
    end
  end
end
