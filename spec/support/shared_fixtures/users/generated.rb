require_relative '../shared_fixture'

# For many factories, we often need one instance
# without any customized attributes.
# Thus we expose them dynamically as AnyFixture,
# so they will be loaded only once.
%i[
  anonymous
].each do |factory_key|
  ::SharedFixture.register! factory_key do
    FactoryBot.create factory_key
  end
end
