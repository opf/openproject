class ParallelHelper
  def self.port_for_ldap
    ENV.fetch('TEST_ENV_NUMBER', '1').to_i + 12389
  end

  def self.port_for_app
    ENV.fetch('TEST_ENV_NUMBER', '1').to_i + 3000
  end
end
