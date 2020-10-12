require_relative '../shared_fixture'

::SharedFixture.register! :admin do
  FactoryBot.create :admin,
                    password: 'adminADMIN!',
                    password_confirmation: 'adminADMIN!'
end
