require File.expand_path('../../spec_helper', __FILE__)

describe Timelines::TimelinesReportingsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.xml' do
    describe 'w/o a given project' do
      it 'renders a 404 Not Found page' do
        get 'index', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ an unknown project' do
      it 'renders a 404 Not Found page' do
        get 'index', :project_id => '4711', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      def fetch
        get 'index', :project_id => project.identifier, :format => 'xml'
      end
      let(:permission) { :view_reportings }
      it_should_behave_like "a controller action which needs project permissions"

      describe 'w/o any reportings within the project' do
        it 'assigns an empty reportings array' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          assigns(:reportings).should == []
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          response.should render_template('timelines/timelines_reportings/index', :formats => ["api"])
        end
      end

      describe 'w/ 3 reportings within the project' do
        before do
          @created_reportings = [
            FactoryGirl.create(:timelines_reporting, :project_id => project.id),
            FactoryGirl.create(:timelines_reporting, :project_id => project.id),
            FactoryGirl.create(:timelines_reporting, :reporting_to_project_id => project.id)
          ]
        end

        it 'assigns a reportings array containing all three elements' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          assigns(:reportings).should == @created_reportings
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          response.should render_template('timelines/timelines_reportings/index', :formats => ["api"])
        end

        describe 'w/ ?only=via_source' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index', :project_id => project.identifier, :format => 'xml', :only => 'via_source'
            assigns(:reportings).should == @created_reportings[0..1]
          end
        end

        describe 'w/ ?only=via_target' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index', :project_id => project.identifier, :format => 'xml', :only => 'via_target'
            assigns(:reportings).should == @created_reportings[2..2]
          end
        end
      end
    end
  end

  describe 'index.html' do
    let(:project) { FactoryGirl.create(:project, :is_public => false) }
    def fetch
      get 'index', :project_id => project.identifier
    end
    let(:permission) { :view_reportings }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'show.xml' do
    describe 'w/o a valid reporting id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => '4711', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', :project_id => '4711', :id => '1337', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :project_id => project.id, :id => '1337', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'w/ a valid reporting id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => reporting.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        def fetch
          get 'show', :project_id => project.id, :id => reporting.id, :format => 'xml'
        end
        let(:permission) { :view_reportings }
        it_should_behave_like "a controller action which needs project permissions"

        it 'assigns the reporting' do
          get 'show', :project_id => project.id, :id => reporting.id, :format => 'xml'
          assigns(:reporting).should == reporting
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.id, :id => reporting.id, :format => 'xml'
          response.should render_template('timelines/timelines_reportings/index', :formats => ["api"])
        end
      end
    end
  end

  describe 'show.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }
    def fetch
      get 'show', :project_id => project.identifier, :id => reporting.id
    end
    let(:permission) { :view_reportings }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'new.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    def fetch
      FactoryGirl.create(:project, :is_public => true) # reporting candidate

      get 'new', :project_id => project.identifier
    end
    let(:permission) { :edit_reportings }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'create.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    def fetch
      post 'create', :project_id => project.identifier,
                     :reporting  => FactoryGirl.build(:timelines_reporting,
                                                  :project_id => project.id).attributes
    end
    let(:permission) { :edit_reportings }
    def expect_redirect_to
      timelines_project_reportings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'edit.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }

    def fetch
      get 'edit', :project_id => project.identifier,
                  :id         => reporting.id
    end
    let(:permission) { :edit_reportings }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }

    def fetch
      post 'update', :project_id => project.identifier,
                     :id         => reporting.id,
                     :reporting => {}
    end
    let(:permission) { :edit_reportings }
    def expect_redirect_to
      timelines_project_reportings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'confirm_destroy.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }

    def fetch
      get 'confirm_destroy', :project_id => project.identifier,
                             :id         => reporting.id
    end
    let(:permission) { :delete_reportings }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:reporting) { FactoryGirl.create(:timelines_reporting, :project_id => project.id) }

    def fetch
      post 'destroy', :project_id => project.identifier,
                      :id         => reporting.id
    end
    let(:permission) { :delete_reportings }
    def expect_redirect_to
      timelines_project_reportings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end
end
