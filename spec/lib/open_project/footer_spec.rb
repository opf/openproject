require 'spec_helper'
require 'open_project/footer'

describe OpenProject::Footer do
  describe '.add_content' do
    context 'empty content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("OpenProject", "footer")
      end
      it {OpenProject::Footer.content.class.should == Hash}
      it {OpenProject::Footer.content["OpenProject"].should == "footer"}
    end

    context 'existing content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("OpenProject", "footer")
        OpenProject::Footer.add_content("footer_2", "footer 2")
      end

      it { OpenProject::Footer.content.count.should == 2}
      it { OpenProject::Footer.content.should == {"OpenProject" => "footer", "footer_2" => "footer 2"}}
    end
  end
end
