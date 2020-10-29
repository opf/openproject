Shindo.tests('AWS::Glacier | glacier archive tests', ['aws']) do
  pending if Fog.mocking?

  Fog::AWS[:glacier].create_vault('Fog-Test-Vault-upload')

  tests('single part upload') do
    id = Fog::AWS[:glacier].create_archive('Fog-Test-Vault-upload', 'data body').headers['x-amz-archive-id']
    Fog::AWS[:glacier].delete_archive('Fog-Test-Vault-upload', id)
  end

  #amazon won't let us delete the vault because it has been written to in the past day

end
