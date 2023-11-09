module EnterpriseHelper
  def write_augur_to_gon
    gon.augur_url = OpenProject::Configuration.enterprise_trial_creation_host
    gon.token_version = OpenProject::Token::VERSION
  end

  def translated_enterprise_features(token)
    return '' unless token.features.present?

    token
      .features
      .map(&:to_s)
      .map { |feature| I18n.t('admin.enterprise.features.' + feature, default: feature) }
      .join(', ')
  end

  def write_trial_key_to_gon
    trial_key = Token::EnterpriseTrialKey.find_by(user_id: User.system.id)
    if trial_key
      gon.ee_trial_key = {
        value: trial_key.value,
        created: trial_key.created_at
      }
    end
  end
end
