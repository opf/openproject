describe Gon do
  describe '.rabl' do

    before :each do
      Gon.clear
      controller.instance_variable_set('@objects', objects)
    end

    let(:controller) { ActionController::Base.new }
    let(:objects) { [1, 2] }

    context 'render template with deprecation' do
      it 'still works' do
        Gon.rabl 'spec/test_data/sample.rabl', :controller => controller
        expect(Gon.objects.length).to eq(2)
      end
    end

    context 'option locals' do
      it 'works without locals object properly' do
        Gon.rabl(
          :template   => 'spec/test_data/sample.rabl',
          :controller => controller
        )
        expect(Gon.objects.map { |it| it['object']['inspect'] }).to eq(%w(1 2))
      end

      it 'works with different locals object' do
        Gon.rabl(
          :template   => 'spec/test_data/sample.rabl',
          :controller => controller,
          :locals     => { :objects => [3, 4] }
        )
        expect(Gon.objects.map { |it| it['object']['inspect'] }).to eq(%w(3 4))
      end
    end

    it 'works if rabl is included' do
      Gon.rabl :template => 'spec/test_data/sample.rabl', :controller => controller
      expect(Gon.objects.length).to eq(2)
    end

    it 'works with ActionView::Helpers' do
      Gon.rabl :template => 'spec/test_data/sample_with_helpers.rabl', :controller => controller
      expect(Gon.objects.first['object']['time_ago']).to eq('about 6 hours')
    end

    it 'raise exception if rabl is not included' do
      Gon.send :remove_const, 'Rabl'
      expect { Gon.rabl :template => 'spec/test_data/sample.rabl', :controller => controller }.to raise_error(NameError)
      load 'rabl.rb'
      load 'gon/rabl.rb'
    end

    context '.template_path' do
      context 'template is specified' do

        it 'add the extension if not included in the template name' do
          expect(Gon::EnvFinder.send(:template_path, { :template => 'spec/test_data/sample' }, 'rabl')).to eql('spec/test_data/sample.rabl')
        end

        it 'return the specified template' do
          expect(Gon::EnvFinder.send(:template_path, { :template => 'spec/test_data/sample.rabl' }, 'rabl')).to eql('spec/test_data/sample.rabl')
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
            expect(Gon::EnvFinder.send(:template_path, { :controller => controller }, 'rabl')).to eql('app/views/action_controller/base/show.json.rabl')
          end
        end

      end
    end

  end

end
