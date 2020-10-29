describe Gon do

  describe '.template_path' do
    context 'template is specified' do

      it 'add the extension if not included in the template name' do
        expect(Gon::EnvFinder.send(:template_path, { :template => 'spec/test_data/sample' }, 'jbuilder')).to eql('spec/test_data/sample.jbuilder')
      end

      it 'return the specified template' do
        expect(Gon::EnvFinder.send(:template_path, { :template => 'spec/test_data/sample.jbuilder' }, 'jbuilder')).to eql('spec/test_data/sample.jbuilder')
      end

    end

    context 'template is not specified' do

      before do
        Gon.clear
        controller.instance_variable_set('@objects', objects)
        controller.action_name = 'show'
      end

      let(:controller) { ActionController::Base.new }
      let(:objects) { [1, 2] }

      context 'the action doesn as a template at a different format' do
        it 'return the same template as the action with rabl extension' do
          expect(Gon::EnvFinder.send(:template_path, { :controller => controller }, 'jbuilder')).to eql('app/views/action_controller/base/show.json.jbuilder')
        end
      end

    end
  end

end
