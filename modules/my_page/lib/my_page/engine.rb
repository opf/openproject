module MyPage
  class Engine < ::Rails::Engine
    isolate_namespace MyPage

    include OpenProject::Plugins::ActsAsOpEngine

    config.to_prepare do
      MyPage::GridRegistration.register!
    end
  end
end
