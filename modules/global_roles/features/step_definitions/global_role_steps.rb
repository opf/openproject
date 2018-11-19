#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Given /^there is the global permission "(.+)?" of the module "(.+)?"$/ do |perm_name, perm_module|
  Redmine::AccessControl.map do |map|
    map.project_module perm_module.to_sym do |mod|
      mod.permission perm_name.to_sym, { dont: :care }, project_module: perm_module.to_sym, global: true
    end
  end
end

Given /^the global permission "(.+)?" of the module "(.+)?" is defined$/ do |perm_name, perm_module|
  as_admin do
    permissions = Redmine::AccessControl.modules_permissions(perm_module)
    permissions.detect { |p| p.name == perm_name.to_sym && p.global? }.should_not be_nil
  end
end

Given /^there is a global [rR]ole "([^\"]*)"$/ do |name|
  FactoryBot.create(:global_role, name: name) unless GlobalRole.find_by_name(name)
end

Given /^the global [rR]ole "([^\"]*)" may have the following [rR]ights:$/ do |role, table|
  r = GlobalRole.find_by_name(role)
  fail "No such role was defined: #{role}" unless r
  as_admin do
    available_perms = Redmine::AccessControl.permissions.collect(&:name)
    r.permissions = []

    table.raw.each do |perm|
      permission = perm.first
      unless permission.blank?
        permission = permission.tr(' ', '_').underscore.to_sym
        if available_perms.include?(:"#{permission}")
          r.add_permission! permission
        end
      end
    end

    r.save!
  end
end

Given /^the [Uu]ser (.+) has the global role (.+)$/ do |user, role|
  user = User.find_by_login(user.delete("\""))
  role = GlobalRole.find_by_name(role.delete("\""))

  as_admin do
    FactoryBot.create(:principal_role, principal: user, role: role)
  end
end

When /^I select the available global role (.+)$/ do |role|
  r = GlobalRole.find_by_name(role.delete("\""))
  fail "No such role was defined: #{role}" unless r
  steps %(
    When I check "principal_role_role_ids_#{r.id}"
  )
end

When /^I delete the assigned role (.+)$/ do |role|
  g = GlobalRole.find_by_name(role.delete("\""))
  fail "No such role was defined: #{role}" unless g
  fail 'More than one or no principal has this role' if g.principal_roles.length != 1

  steps %(
    When I follow "Delete" within "#principal_role-#{g.principal_roles[0].id}"
  )
end

Then /^I should (not )?see block with "(.+)?"$/ do |negative, id|
  unless negative
    expect(page).to have_css("#{id}", visible: true)
  else
    expect(page).to have_css("#{id}", visible: false)
  end
end
