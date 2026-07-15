# frozen_string_literal: true

# Self-service variant of the administration user attributes form. Renders the
# same section-grouped built-in + custom fields, but without the admin-only
# "Account" section, and shows non-writable built-ins read-only (with the
# provider-login caption) rather than disabled.
class My::AttributesForm < Users::Form::AttributesForm
  # The parent stores its `form do` block in a (non-inherited) class instance
  # variable, so the block must be re-declared here. Self-service renders only
  # the custom-field sections, never the admin-only account section.
  form do |f|
    user_sections(f)
  end

  def initialize(user:)
    super(user:, contract: Users::UpdateContract.new(user, User.current))
  end

  private

  # Users cannot move themselves between departments; the field is always
  # read-only on the self-service account page.
  def department_editable?
    false
  end

  def editability(key)
    return {} if @contract.writable?(key.to_sym)

    options = { readonly: true }
    caption = readonly_caption(key.to_s)
    options[:caption] = caption if caption
    options
  end

  def readonly_caption(key)
    return unless %w[firstname lastname mail].include?(key)

    if authenticates_externally?
      I18n.t("user.text_change_disabled_for_provider_login")
    elsif key == "mail"
      I18n.t("user.text_change_mail_disabled_by_administrator")
    end
  end

  def authenticates_externally?
    @user.uses_external_authentication? || @user.ldap_auth_source_id.present?
  end

  # Custom fields a user may not edit themselves (editable: false) are shown
  # read-only on their own account; admins manage those on the admin user form.
  def form_arguments(custom_field)
    args = super
    args[:disabled] = true unless custom_field.editable?
    args
  end
end
