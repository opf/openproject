class PermissionMock
  attr_reader :user, :permitted_entities

  def initialize(user)
    @user = user
    @permitted_entities = Hash.new do |hash, entity_project_or_global|
      hash[entity_project_or_global] = Array.new
    end
  end

  def on_project(*permissions, project:)
    puts "Mocking #{permissions} on #{project.id}"
    permitted_entities[project] += permissions
  end

  def on_work_package(*permissions, work_package:)
    puts "Mocking #{permissions} on #{work_package.id}"
    permitted_entities[work_package] += permissions
  end

  def globally(*permissions)
    puts "Mocking #{permissions} globally"
    permitted_entities[:global] += permissions
  end
end

module MockedPermissionHelper
  mattr_accessor :mocked_permission_cache

  def mock_permissions_for(user)
    permission_mock = PermissionMock.new(user)

    yield permission_mock if block_given?

    self.mocked_permission_cache ||= {}
    self.mocked_permission_cache[user] = permission_mock
  end
end

RSpec.configure do |config|
  config.include MockedPermissionHelper

  config.before do
    puts "Mocking permissions... Something in cache? #{MockedPermissionHelper.mocked_permission_cache.present?}"
    next if MockedPermissionHelper.mocked_permission_cache.blank?

    (self.mocked_permission_cache || {}).each do |user, mock|
      permissible_service = user.send(:user_permissible_service) # access the private instance

      allow(permissible_service).to receive(:allowed_globally?) do |permission|
        puts "Checking #{permission} globally"
        mock.pepermitted_entities[:global].include?(permission)
      end

      allow(permissible_service).to receive(:allowed_in_project?) do |permission, project_or_projects|
        projects = Array(project_or_projects)

        projects.all? do |project|
          mock.permitted_entities[project].include?(permission)
        end
      end

      allow(permissible_service).to receive(:allowed_in_any_project?) do |permission|
        mock
          .permitted_entities
          .select { |k, _| k.is_a?(Project) }
          .values
          .flat_map
          .include?(permission)
      end

      allow(permissible_service).to receive(:allowed_in_any_entity?) do |permission, entity_class, in_project:|
        all_permitted_entties = mock.permitted_entities

        next true if in_project && mock.permitted_entities[in_project].include?(permission)

        filtered_entities = if in_project
                              all_permitted_entties.select do |k, _|
                                k.is_a?(entity_class) && k.respond_to?(:project) && k.project == in_project
                              end
                            else
                              all_permitted_entties.select { |k, _| k.is_a?(entity_class) }
                            end

        filtered_entities
          .values
          .flat_map
          .include?(permission)
      end

      allow(permissible_service).to receive(:allowed_in_entity?) do |permission, entity|
        (entity.respond_to?(:project) && mock.permitted_entities[entity.project].include?(permission)) ||
        mock.permitted_entities[entity].include?(permission)
      end
    end
  end
end
