Shindo.tests('AWS::Glacier | glacier archive tests', ['aws']) do
  pending if Fog.mocking?

  Fog::AWS[:glacier].create_vault('Fog-Test-Vault-upload')

  tests('initiate and abort') do
    id = Fog::AWS[:glacier].initiate_multipart_upload('Fog-Test-Vault-upload', 1024*1024).headers['x-amz-multipart-upload-id']
    returns(true){ Fog::AWS[:glacier].list_multipart_uploads('Fog-Test-Vault-upload').body['UploadsList'].map {|item| item['MultipartUploadId']}.include?(id)}
    Fog::AWS[:glacier].abort_multipart_upload('Fog-Test-Vault-upload', id)
    returns(false){ Fog::AWS[:glacier].list_multipart_uploads('Fog-Test-Vault-upload').body['UploadsList'].map {|item| item['MultipartUploadId']}.include?(id)}
  end

  tests('do multipart upload') do
    hash = Fog::AWS::Glacier::TreeHash.new
    id = Fog::AWS[:glacier].initiate_multipart_upload('Fog-Test-Vault-upload', 1024*1024).headers['x-amz-multipart-upload-id']
    part = 't'*1024*1024
    hash_for_part = hash.add_part(part)
    Fog::AWS[:glacier].upload_part('Fog-Test-Vault-upload', id, part, 0, hash_for_part)

    part_2 = 'u'*1024*1024
    hash_for_part_2 = hash.add_part(part_2)
    Fog::AWS[:glacier].upload_part('Fog-Test-Vault-upload', id, part_2, 1024*1024, hash_for_part_2)

    archive = Fog::AWS[:glacier].complete_multipart_upload('Fog-Test-Vault-upload', id, 2*1024*1024, hash.hexdigest).headers['x-amz-archive-id']

    Fog::AWS[:glacier].delete_archive('Fog-Test-Vault-upload', archive)
  #amazon won't let us delete the vault because it has been written to in the past day
  end
end
