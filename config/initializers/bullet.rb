if defined?(Bullet) && Rails.env.development?
  OpenProject::Application.configure do
    config.after_initialize do
      Bullet.enable = true
      # Bullet.alert = true
      Bullet.bullet_logger = true
      Bullet.console = true
      # Bullet.growl = true
      Bullet.rails_logger = true
      Bullet.disable_browser_cache = true
    end
  end
end