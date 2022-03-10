module API::V3::FileLinks
  class CreateEndpoint < API::Utilities::Endpoints::Create
    include ::API::V3::Utilities::Endpoints::V3Deductions
    include ::API::V3::Utilities::Endpoints::V3PresentSingle

    def process(request, params_elements)
      global_result = ServiceResult.new(
        success: true,
        result: []
      )
      params_elements.each do |params|
        one_result = super(request, params)
        global_result.add_dependent!(one_result)
        global_result.result << one_result.result
      end
      global_result
    end

    def present_success(request, call)
      render_representer.create(
        call.result,
        self_link: request.api_v3_paths.file_links(request.work_package.id),
        current_user: request.current_user
      )
    end

    protected

    def build_error_from_result(result)
      ActiveModel::Errors.new result.first
    end

    private

    def params_modifier
      ->(params) do
        params[:creator_id] = current_user.id
        params[:container_id] = work_package.id
        params[:container_type] = work_package.class.name
        params
      end
    end
  end
end
