def mock_global_permissions(permissions)
  mapped = permissions.map do |name, options|
    mock_permissions(name, options.merge(global: true))
  end

  mapped_modules = permissions.map do |_, options|
    options[:project_module] || 'Foo'
  end.uniq

  allow(OpenProject::AccessControl).to receive(:modules).and_wrap_original do |m, *args|
    m.call(*args) + mapped_modules.map { |name| { order: 0, name: name } }
  end
  allow(OpenProject::AccessControl).to receive(:permissions).and_wrap_original do |m, *args|
    m.call(*args) + mapped
  end
  allow(OpenProject::AccessControl).to receive(:global_permissions).and_wrap_original do |m, *args|
    m.call(*args) + mapped
  end
end

def mock_permissions(name, options = {})
  ::OpenProject::AccessControl::Permission.new(
    name,
    { does_not: :matter },
    { project_module: 'Foo', public: false, global: false }.merge(options)
  )
end
