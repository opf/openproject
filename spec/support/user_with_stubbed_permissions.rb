shared_context 'user with stubbed permissions' do |attributes = {}|
  let(:user) do
    raise "'let(:permissions)' needs to be defined" unless defined?(:permissions)
    raise "'let(:project)' needs to be defined" unless defined?(:project)

    FactoryBot.build_stubbed(:user, **attributes).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |queried_permission, queried_project|
        project == queried_project && permissions.include?(queried_permission)
      end
    end
  end
end
