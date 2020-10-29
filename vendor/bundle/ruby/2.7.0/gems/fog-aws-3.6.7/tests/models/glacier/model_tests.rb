Shindo.tests('AWS::Glacier | models', ['aws', 'glacier']) do
  pending if Fog.mocking?
  tests('success') do
    tests('vaults') do
      tests('getting a missing vault') do
        returns(nil) { Fog::AWS[:glacier].vaults.get('no-such-vault') }
      end

      vault = nil
      tests('creating a vault') do
        vault = Fog::AWS[:glacier].vaults.create :id => 'Fog-Test-Vault'
        tests("id is Fog-Test-Vault").returns('Fog-Test-Vault') {vault.id}
      end

      tests('all') do
        tests('contains vault').returns(true) { Fog::AWS[:glacier].vaults.map {|vault| vault.id}.include?(vault.id)}
      end

      tests('destroy') do
        vault.destroy
        tests('removes vault').returns(nil) {Fog::AWS[:glacier].vaults.get(vault.id)}
      end
    end

    tests("archives") do
      vault = Fog::AWS[:glacier].vaults.create :id => 'Fog-Test-Vault-upload'
      tests('create') do
        archive = vault.archives.create(:body => 'data')
        tests('sets id').returns(true) {!archive.id.nil?}
        archive.destroy
      end
      tests('create multipart') do
        body = StringIO.new('x'*1024*1024*2)
        body.rewind
        archive = vault.archives.create(:body => body, :multipart_chunk_size => 1024*1024)
        tests('sets id').returns(true) {!archive.id.nil?}
        archive.destroy
      end
    end

    vault = Fog::AWS[:glacier].vaults.create :id => 'Fog-Test-Vault'
    tests("jobs") do
      tests('all').returns([]) {vault.jobs}
    end
    vault.destroy
  end
end
