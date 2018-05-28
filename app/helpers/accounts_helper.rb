module AccountsHelper
  class Footer
    include OpenProject::TextFormatting

    attr_reader :source

    def initialize(source)
      @source = source
    end

    def to_html
      format_text source
    end
  end

  def login_field(form)
    form.text_field :login, size: 25, required: true
  end

  def email_field(form)
    form.text_field :mail, required: true
  end

  ##
  # Hide the email field in the registration form if the `email_login` setting
  # is active. However, if an auth source is present, do show it independently from
  # the `email_login` setting as we can't say if the auth source's login is the email address.
  def registration_show_email?
    !Setting.email_login? || @user.auth_source_id.present?
  end

  def registration_footer
    footer = registration_footer_for lang: I18n.locale.to_s

    Footer.new(footer).to_html if footer
  end

  ##
  # Gets the registration footer in the given language.
  # If registration footers are defined via the OpenProject configuration
  # then any footers defined via settings will be ignored.
  #
  # @param lang [String] ISO 639-1 language code (e.g. 'en', 'de')
  def registration_footer_for(lang:)
    if footer = OpenProject::Configuration.registration_footer.presence
      footer[lang.to_s].presence
    else
      Setting.registration_footer[lang.to_s].presence
    end
  end
end
