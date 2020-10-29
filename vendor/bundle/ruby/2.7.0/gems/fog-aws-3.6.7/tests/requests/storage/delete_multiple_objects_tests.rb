Shindo.tests('AWS::Storage | delete_multiple_objects', ['aws']) do
  @directory = Fog::Storage[:aws].directories.create(:key => 'fogobjecttests-' + Time.now.to_i.to_s(32))

  tests("doesn't alter options") do
    version_id = {'fog_object' => ['12345']}
    options = {:quiet => true, 'versionId' => version_id}
    Fog::Storage[:aws].delete_multiple_objects(@directory.identity, ['fog_object'], options)

    test(":quiet is unchanged") { options[:quiet] }
    test("'versionId' is unchanged") { options['versionId'] == version_id }
  end
end
