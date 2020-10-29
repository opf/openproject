Shindo.tests('AWS::Glacier | glacier vault requests', ['aws']) do
  pending if Fog.mocking?

  topic_arn = Fog::AWS[:sns].create_topic( 'fog_test_glacier_topic').body['TopicArn']
  Fog::AWS[:glacier].create_vault('Fog-Test-Vault')

  tests('list_vaults') do
    returns(true){Fog::AWS[:glacier].list_vaults.body['VaultList'].map {|data| data['VaultName']}.include?('Fog-Test-Vault')}
  end

  tests('describe_vault') do
    returns('Fog-Test-Vault'){Fog::AWS[:glacier].describe_vault('Fog-Test-Vault').body['VaultName']}
  end

  tests('set_vault_notification_configuration') do
    Fog::AWS[:glacier].set_vault_notification_configuration 'Fog-Test-Vault', topic_arn, ['ArchiveRetrievalCompleted']
  end

  tests('get_vault_notification_configuration') do
    returns('SNSTopic' => topic_arn, 'Events' => ['ArchiveRetrievalCompleted']){ Fog::AWS[:glacier].get_vault_notification_configuration( 'Fog-Test-Vault').body}
  end

  tests('delete_vault_notification_configuration') do
    Fog::AWS[:glacier].delete_vault_notification_configuration( 'Fog-Test-Vault')
    raises(Excon::Errors::NotFound){Fog::AWS[:glacier].get_vault_notification_configuration( 'Fog-Test-Vault')}
  end

  tests('delete_vault') do
    Fog::AWS[:glacier].delete_vault( 'Fog-Test-Vault')
    raises(Excon::Errors::NotFound){Fog::AWS[:glacier].describe_vault( 'Fog-Test-Vault')}
  end

  Fog::AWS[:sns].delete_topic topic_arn

end
