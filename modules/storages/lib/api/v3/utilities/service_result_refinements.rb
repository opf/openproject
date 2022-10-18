module API::V3::Utilities::ServiceResultRefinements
  refine ServiceResult do
    def match(on_success:, on_failure:)
      if success?
        on_success.call(result)
      else
        on_failure.call(result)
      end
    end
  end
end
