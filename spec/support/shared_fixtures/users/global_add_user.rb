require_relative '../shared_fixture'

::SharedFixture.register! :global_add_user do
  global_add_user_role = FactoryBot.create :global_role, name: 'Global add user role', permissions: %i[add_user]
  FactoryBot.create(:user).tap do |user|

    FactoryBot.create(:global_member,
                      principal: user,
                      roles: [global_add_user_role])

  end
end
