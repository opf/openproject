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
    permissions.detect{|p| p.name == perm_name.to_sym && p.global?}.should_not be_nil
  end
end

Given /^there is a global [rR]ole "([^\"]*)"$/ do |name|
  GlobalRole.spawn.tap { |r| r.name = name }.save! unless GlobalRole.find_by_name(name)
end

Given /^the global [rR]ole "([^\"]*)" may have the following [rR]ights:$/ do |role, table|
  r = GlobalRole.find_by_name(role)
  raise "No such role was defined: #{role}" unless r
  as_admin do
    available_perms = Redmine::AccessControl.permissions.collect(&:name)
    r.permissions = []

    table.raw.each do |_perm|
      perm = _perm.first
      unless perm.blank?
        perm = perm.gsub(" ", "_").underscore.to_sym
        if available_perms.include?(:"#{perm}")
          r.permissions << perm
        end
      end
    end

    r.save!
  end
end

When /^I select the available role (.+)$/ do |role|
  r = GlobalRole.find_by_name(role.gsub("\"", ""))
  raise "No such role was defined: #{role}" unless r
  steps %Q{
    When I check "principal_role_role_ids_#{r.id}"
  }
end