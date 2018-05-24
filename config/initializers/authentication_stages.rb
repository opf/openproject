OpenProject::Authentication::Stage
  .register(
    :consent,
    active: ->() { Setting.consent_required? }
  ) {
    account_consent_path
  }
