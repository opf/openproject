require File.expand_path('../../spec_helper', __FILE__)

describe OpenProject::GithubIntegration do
  before do
    Setting.stub(:host_name).and_return('example.net')
  end

  describe '.parse_work_package' do
    it 'should return an empty array for an empty source' do
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :parse_work_package, '')
      expect(result).to eql([])
    end

    it 'should find a plain work package url' do
      source = 'Blabla\nhttps://example.net/work_packages/234\n'
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :parse_work_package, source)
      expect(result).to eql([234])
    end

    it 'should find a work package url in markdown link syntax' do
      source = 'Blabla\n[WP 234](https://example.net/work_packages/234)\n'
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :parse_work_package, source)
      expect(result).to eql([234])
    end

    it 'should find multiple work package urls' do
      source = "I reference https://example.net/work_packages/434\n and Blabla\n[WP 234](https://example.net/wp/234)\n"
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :parse_work_package, source)
      expect(result).to eql([434, 234])
    end

  end
end
