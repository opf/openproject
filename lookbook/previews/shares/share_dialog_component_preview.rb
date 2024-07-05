module Shares
  class ShareDialogComponentPreview < Lookbook::Preview
    def project_query
      user = FactoryBot.build_stubbed(:admin)
      query = FactoryBot.build_stubbed(:project_query, user:)
      strategy = SharingStrategies::ProjectQueryStrategy.new(query, user:)
      errors = []
      shares = []

      render(Shares::ShareDialogComponent.new(strategy:, shares:, errors:))
    end

    def work_package
      user = FactoryBot.build_stubbed(:admin)
      work_package = FactoryBot.build_stubbed(:work_package)
      strategy = SharingStrategies::WorkPackageStrategy.new(work_package, user:)
      errors = []
      shares = []

      render(Shares::ShareDialogComponent.new(strategy:, shares:, errors:))
    end
  end
end
