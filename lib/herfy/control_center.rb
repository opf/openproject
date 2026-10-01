# frozen_string_literal: true

# Herfy Control Center is the identity source for OpenProject. This module
# turns Control Center's per-user claims (from the OIDC id_token at login, or
# from /api/users/export in the scheduled sync) into OpenProject state:
#
#   * employee id / role / manager / department / designation -> user custom fields
#   * is_admin claim                                          -> User#admin
#   * deactivated users                                       -> locked accounts
#
# Group membership comes from the standard OIDC "groups" claim via the
# provider's own sync_groups option, not from here.
module Herfy
  module ControlCenter
    PROVIDER_SLUG = "herfy-control-center"

    FIELDS = {
      employee_id: "Employee ID",
      role: "Role",
      manager: "Manager",
      department: "Department",
      designation: "Designation"
    }.freeze

    module_function

    def ensure_custom_fields!
      FIELDS.values.index_with do |name|
        UserCustomField.find_by(name:) ||
          UserCustomField.create!(name:, field_format: "string", admin_only: false, editable: false,
                                  user_custom_field_section: UserCustomFieldSection.first_or_create!(name: "Herfy"))
      end
    end

    # claims: normalised hash with string keys
    #   empid, roles (Array), manager_email, manager_name, department, designation, is_admin
    def apply_claims(user, claims)
      fields = ensure_custom_fields!
      values = {
        FIELDS[:employee_id] => claims["empid"],
        FIELDS[:role] => Array(claims["roles"]).join(", "),
        FIELDS[:manager] => manager_label(claims),
        FIELDS[:department] => claims["department"],
        FIELDS[:designation] => claims["designation"]
      }
      user.custom_field_values = values.to_h { |name, value| [fields.fetch(name).id, value.to_s] }
      user.admin = ActiveModel::Type::Boolean.new.cast(claims["is_admin"]) unless claims["is_admin"].nil?
      user.save!(validate: false)
      user
    end

    def manager_label(claims)
      email = claims["manager_email"].presence
      name = claims["manager_name"].presence
      return email.to_s if name.nil?

      email ? "#{name} <#{email}>" : name
    end

    # Claims from an id_token / userinfo payload.
    def claims_from_oidc(raw)
      raw = JSON.parse(raw.to_json) # plain Hash/Array: safe to keep in the session
      raw.slice("empid", "roles", "manager_email", "department", "designation", "is_admin")
    end

    # Claims from one /api/users/export record.
    def claims_from_export(record)
      identity = record.fetch("identity", {})
      reporting = record.fetch("reporting", {})
      profile = record.fetch("org_profile", {})
      {
        "empid" => identity["empid"],
        "roles" => identity["roles"],
        "manager_email" => reporting["manager_email"],
        "department" => profile["department"],
        "designation" => profile["designation"]
      }
    end

    def provider
      OpenIDConnect::Provider.find_by(slug: PROVIDER_SLUG)
    end
  end
end
