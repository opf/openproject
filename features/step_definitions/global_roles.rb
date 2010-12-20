Given /^there is the global permission "(.+)?" of the module "(.+)?"$/ do |perm_name, perm_module|
  Redmine::AccessControl.map do |map|
    map.project_module perm_module.to_sym do |mod|
      mod.permission perm_name.to_sym, {:dont => :care}, {:project_module => perm_module.to_sym, :global => true}
    end
  end
end

Given /^the global permission "(.+)?" of the module "(.+)?" is defined$/ do |perm_name, perm_module|
  as_admin do
    permissions = Redmine::AccessControl.modules_permissions(perm_module)
    debugger
    permissions.detect{|p| p.name == perm_name.to_sym && p.global?}.should_not be_nil
  end
end