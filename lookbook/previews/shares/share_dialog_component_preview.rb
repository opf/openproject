module Shares
  # @logical_path OpenProject/Shares
  class ShareDialogComponentPreview < Lookbook::Preview
    def project_query
      user = FactoryBot.build_stubbed(:admin)
      query = FactoryBot.build_stubbed(:project_query, user:)
      strategy = SharingStrategies::ProjectQueryStrategy.new(query, user:, query_params: {})
      errors = []

      render(Shares::ShareDialogComponent.new(strategy:, errors:, open: true))
    end

    def work_package
      user = FactoryBot.build_stubbed(:admin)
      work_package = FactoryBot.build_stubbed(:work_package)
      strategy = SharingStrategies::WorkPackageStrategy.new(work_package, user:, query_params: {})
      errors = []

      render(Shares::ShareDialogComponent.new(strategy:, errors:, open: true))
    end
  end
end
