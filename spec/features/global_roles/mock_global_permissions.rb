# frozen_string_literal: true

# Allows mocking a specific global permission
# that's not registered in an initializer by providing
# a name and a set of options.
# It also takes care of mocking a translation for each provided
# permission only if it wasn't already an existing key, preventing
# a mock of an already present translation.
RSpec.shared_context "with mocked global permissions" do |permissions|
  before do
    mock_global_permissions(permissions)
  end

  around do |example|
    permission_translation_mocker = PermissionTranslationMocker.new(permissions)

    permission_translation_mocker.register

    example.run
  ensure
    permission_translation_mocker.unregister
  end
end

def mock_global_permissions(permissions)
  mapped = permissions.map do |name, options|
    mock_permissions(name, options.reverse_merge(permissible_on: :global))
  end

  mapped_modules = permissions.map do |_, options|
    options[:project_module] || "Foo"
  end.uniq

  allow(OpenProject::AccessControl).to receive(:modules).and_wrap_original do |m, *args|
    m.call(*args) + mapped_modules.map { |name| { order: 0, name: } }
  end
  allow(OpenProject::AccessControl).to receive(:permissions).and_wrap_original do |m, *args|
    m.call(*args) + mapped
  end
  allow(OpenProject::AccessControl).to receive(:global_permissions).and_wrap_original do |m, *args|
    m.call(*args) + mapped
  end
end

def mock_permissions(name, options = {})
  OpenProject::AccessControl::Permission.new(
    name,
    { does_not: :matter },
    permissible_on: :project,
    project_module: "Foo",
    public: false,
    **options
  )
end

class PermissionTranslationMocker
  def initialize(permissions)
    @permissions = permissions
  end

  def register
    @permissions.each do |name, _options|
      unless translation_already_registered?(name)
        I18n.backend.store_translations(:en, "permission_#{name}": name.humanize)
      end
    end
  end

  def unregister
    @permissions.each do |name, _options|
      unless translation_already_registered?(name)
        I18n.backend.store_translations(:en, "permission_#{name}": name.humanize)
      end
    end
  end

  private

  def translation_already_registered?(name)
    translation_registry[name]
  end

  def translation_registry
    @translation_registry ||= @permissions.to_h do |name, _options|
      [name, I18n.exists?("permissions_#{name}", :en)]
    end
  end
end
