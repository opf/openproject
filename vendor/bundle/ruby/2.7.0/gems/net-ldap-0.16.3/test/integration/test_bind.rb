require_relative '../test_helper'

class TestBindIntegration < LDAPIntegrationTestCase
  INTEGRATION_HOSTNAME = 'ldap.example.org'.freeze

  def test_bind_success
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_timeout
    @ldap.host = "10.255.255.1" # non-routable IP

    error = assert_raise Net::LDAP::Error do
      @ldap.bind BIND_CREDS
    end
    msgs = ['Operation timed out - user specified timeout',
            'Connection timed out - user specified timeout']
    assert_send([msgs, :include?, error.message])
  end

  def test_bind_anonymous_fail
    refute @ldap.bind(BIND_CREDS.merge(password: '')),
           @ldap.get_operation_result.inspect

    result = @ldap.get_operation_result
    assert_equal Net::LDAP::ResultCodeUnwillingToPerform, result.code
    assert_equal Net::LDAP::ResultStrings[Net::LDAP::ResultCodeUnwillingToPerform], result.message
    assert_equal "unauthenticated bind (DN with no password) disallowed",
                 result.error_message
    assert_equal "", result.matched_dn
  end

  def test_bind_fail
    refute @ldap.bind(BIND_CREDS.merge(password: "not my password")),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_cafile
    @ldap.host = INTEGRATION_HOSTNAME
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(ca_file: CA_FILE),
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_bad_hostname_verify_none_no_ca_passes
    @ldap.host = INTEGRATION_HOSTNAME
    @ldap.encryption(
      method:      :start_tls,
      tls_options: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_bad_hostname_verify_none_no_ca_opt_merge_passes
    @ldap.host = '127.0.0.1'
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(verify_mode: OpenSSL::SSL::VERIFY_NONE),
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_bad_hostname_verify_peer_ca_fails
    @ldap.host = '127.0.0.1'
    @ldap.encryption(
      method:      :start_tls,
      tls_options: { verify_mode: OpenSSL::SSL::VERIFY_PEER,
                     ca_file:     CA_FILE },
    )
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionRefusedError do
      @ldap.bind BIND_CREDS
    end
    assert_equal(
      "hostname \"#{@ldap.host}\" does not match the server certificate",
      error.message,
    )
  end

  def test_bind_tls_with_bad_hostname_ca_default_opt_merge_fails
    @ldap.host = '127.0.0.1'
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(ca_file: CA_FILE),
    )
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionRefusedError do
      @ldap.bind BIND_CREDS
    end
    assert_equal(
      "hostname \"#{@ldap.host}\" does not match the server certificate",
      error.message,
    )
  end

  def test_bind_tls_with_bad_hostname_ca_no_opt_merge_fails
    @ldap.host = '127.0.0.1'
    @ldap.encryption(
      method:      :start_tls,
      tls_options: { ca_file: CA_FILE },
    )
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionRefusedError do
      @ldap.bind BIND_CREDS
    end
    assert_equal(
      "hostname \"#{@ldap.host}\" does not match the server certificate",
      error.message,
    )
  end

  def test_bind_tls_with_valid_hostname_default_opts_passes
    @ldap.host = INTEGRATION_HOSTNAME
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                  ca_file:     CA_FILE),
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_valid_hostname_just_verify_peer_ca_passes
    @ldap.host = INTEGRATION_HOSTNAME
    @ldap.encryption(
      method:      :start_tls,
      tls_options: { verify_mode: OpenSSL::SSL::VERIFY_PEER,
                     ca_file:     CA_FILE },
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_bogus_hostname_system_ca_fails
    @ldap.host = '127.0.0.1'
    @ldap.encryption(method: :start_tls, tls_options: {})
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionRefusedError do
      @ldap.bind BIND_CREDS
    end
    assert_equal(
      "hostname \"#{@ldap.host}\" does not match the server certificate",
      error.message,
    )
  end

  def test_bind_tls_with_multiple_hosts
    @ldap.host = nil
    @ldap.hosts = [[INTEGRATION_HOSTNAME, 389], [INTEGRATION_HOSTNAME, 389]]
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                  ca_file:     CA_FILE),
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_multiple_bogus_hosts
    @ldap.host = nil
    @ldap.hosts = [['127.0.0.1', 389], ['bogus.example.com', 389]]
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                  ca_file:     CA_FILE),
    )
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionError do
      @ldap.bind BIND_CREDS
    end
    assert_equal("Unable to connect to any given server: ",
                 error.message.split("\n").shift)
  end

  def test_bind_tls_with_multiple_bogus_hosts_no_verification
    @ldap.host = nil
    @ldap.hosts = [['127.0.0.1', 389], ['bogus.example.com', 389]]
    @ldap.encryption(
      method:      :start_tls,
      tls_options: TLS_OPTS.merge(verify_mode: OpenSSL::SSL::VERIFY_NONE),
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_multiple_bogus_hosts_ca_check_only_fails
    @ldap.host = nil
    @ldap.hosts = [['127.0.0.1', 389], ['bogus.example.com', 389]]
    @ldap.encryption(
      method: :start_tls,
      tls_options: { ca_file: CA_FILE },
    )
    error = assert_raise Net::LDAP::Error,
                         Net::LDAP::ConnectionError do
      @ldap.bind BIND_CREDS
    end
    assert_equal("Unable to connect to any given server: ",
                 error.message.split("\n").shift)
  end

  # This test is CI-only because we can't add the fixture CA
  # to the system CA store on people's dev boxes.
  def test_bind_tls_valid_hostname_system_ca_on_travis_passes
    omit "not sure how to install custom CA cert in travis"
    omit_unless ENV['TRAVIS'] == 'true'

    @ldap.host = INTEGRATION_HOSTNAME
    @ldap.encryption(
      method: :start_tls,
      tls_options: { verify_mode: OpenSSL::SSL::VERIFY_PEER },
    )
    assert @ldap.bind(BIND_CREDS),
           @ldap.get_operation_result.inspect
  end
end
