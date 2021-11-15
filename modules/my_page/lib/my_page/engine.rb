module MyPage
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    config.to_prepare do
      MyPage::GridRegistration.register!
    end

    initializer 'my_page.conversion' do
      require Rails.root.join('config', 'constants', 'ar_to_api_conversions')

      Constants::ARToAPIConversions.add('grids/my_page': 'grid')
    end
  end
end
