module MockedPermissionHelper
  mattr_accessor :mocked_permission_cache

  def mock_project_permission(*permissions, user:, project:)
    mocked_permissions[user][project] += permissions
  end

  def mock_work_package_permissions(*permissions, user:, work_package:)
    mocked_permissions[user][work_package] += permissions
  end

  def mock_global_permissions(*permissions, user:)
    mocked_permissions[user][:global] += permissions
  end

  def mocked_permissions
    self.mocked_permission_cache ||= Hash.new do |hash, user|
      hash[user] = Hash.new do |hash2, entity_project_or_global|
        hash2[entity_project_or_global] = Array.new
      end
    end
  end
end

RSpec.configure do |config|
  config.include MockedPermissionHelper

  config.before do
    next if MockedPermissionHelper.mocked_permission_cache.blank?

    MockedPermissionHelper.mocked_permission_cache.each do |user, (context, permissions)|
      permissible_service = user.send(:user_permissible_service) # access the private instance

      allow(permissible_service).to receive_messages(
        :allowed_globally?,
        :allowed_in_project?,
        :allowed_in_any_project?,
        :allowed_in_entity?,
        :allowed_in_any_entity?
      ).and_return(false)

      case context
      when :global
        permissions.each do |permission|
          allow(permissible_service).to receive(:allowed_globally?).with(permission).and_return(true)
        end
      when Project
        permissions.each do |permission|
          allow(permissible_service).to receive(:allowed_in_project?).with(permission, context).and_return(true)
          allow(permissible_service).to receive(:allowed_in_any_project?).with(permission).and_return(true)
          allow(permissible_service).to receive(:allowed_in_any_entity?).with(permission, Class,
                                                                              in_project: context).and_return(true)
        end
      else
        permissions.each do |permission|
          allow(permissible_service).to receive(:allowed_in_entity?).with(permission, context).and_return(true)
          allow(permissible_service).to receive(:allowed_in_any_entity?).with(permission,
                                                                              context.class).and_return(true)
          if context.respond_to?(:project)
            allow(permissible_service).to receive(:allowed_in_any_entity?).with(permission, context.class,
                                                                                in_project: context.project).and_return(true)
          end
        end
      end
    end
  end

  config.after do
    MockedPermissionHelper.mocked_permission_cache = nil
  end
end
