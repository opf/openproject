require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Impediment do
  let(:user) { @user ||= FactoryGirl.create(:user) }
  let(:role) { @role ||= FactoryGirl.create(:role) }
  let(:type_feature) { @type_feature ||= FactoryGirl.create(:type_feature) }
  let(:type_task) { @type_task ||= FactoryGirl.create(:type_task) }
  let(:issue_priority) { @issue_priority ||= FactoryGirl.create(:priority, :is_default => true) }
  let(:task) { FactoryGirl.build(:task, :type => type_task,
                                    :project => project,
                                    :author => user,
                                    :priority => issue_priority,
                                    :status => status1) }
  let(:feature) { FactoryGirl.build(:work_package, :type => type_feature,
                                        :project => project,
                                        :author => user,
                                        :priority => issue_priority,
                                        :status => status1) }
  let(:version) { FactoryGirl.create(:version, :project => project) }

  let(:project) do
    unless @project
      @project = FactoryGirl.build(:project, :types => [type_feature, type_task])
      @project.members = [FactoryGirl.build(:member, :principal => user,
                                                 :project => @project,
                                                 :roles => [role])]
    end
    @project
  end

  let(:status1) { @status1 ||= FactoryGirl.create(:status, :name => "status 1", :is_default => true) }
  let(:status2) { @status2 ||= FactoryGirl.create(:status, :name => "status 2") }
  let(:type_workflow) { @workflow ||= Workflow.create(:type_id => type_task.id,
                                                 :old_status => status1,
                                                 :new_status => status2,
                                                 :role => role) }
  let(:impediment) { FactoryGirl.build(:impediment, :author => user,
                                                :fixed_version => version,
                                                :assigned_to => user,
                                                :priority => issue_priority,
                                                :project => project,
                                                :type => type_task,
                                                :status => status1)}

  before(:each) do
    ActionController::Base.perform_caching = false

    Setting.stub(:plugin_openproject_backlogs).and_return({"points_burn_direction" => "down",
                                                           "wiki_template"         => "",
                                                           "card_spec"             => "Sattleford VM-5040",
                                                           "story_types"           => [type_feature.id.to_s],
                                                           "task_type"             => type_task.id.to_s })

    User.stub(:current).and_return(user)
    issue_priority.save
    status1.save
    project.save
    type_workflow.save
  end

  describe "class methods" do
    describe :create_with_relationships do
      before(:each) do
        @impediment_subject = "Impediment A"
        role.permissions = [:create_impediments]
        role.save
      end

      shared_examples_for "impediment creation" do
        it { @impediment.subject.should eql @impediment_subject }
        it { @impediment.author.should eql User.current }
        it { @impediment.project.should eql project }
        it { @impediment.fixed_version.should eql version }
        it { @impediment.priority.should eql issue_priority}
        it { @impediment.status.should eql status1 }
        it { @impediment.type.should eql type_task }
        it { @impediment.assigned_to.should eql user }
      end

      shared_examples_for "impediment creation with 1 blocking relationship" do
        it_should_behave_like "impediment creation"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].to.should eql feature }
        it { @impediment.relations_from[0].relation_type.should eql Relation::TYPE_BLOCKS }
      end

      shared_examples_for "impediment creation with no blocking relationship" do
        it_should_behave_like "impediment creation"
        it { @impediment.should have(0).relations_from }
      end

      describe "WITH a blocking relationship to a story" do
        describe "WITH the story having the same version" do
          before(:each) do
            feature.fixed_version = version
            feature.save
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => feature.id.to_s,
                                                                :status_id => status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)

          end

          it_should_behave_like "impediment creation with 1 blocking relationship"
          it { @impediment.should_not be_new_record }
          it { @impediment.relations_from[0].should_not be_new_record }
        end

        describe "WITH the story having another version" do
          before(:each) do
            feature.fixed_version = FactoryGirl.create(:version, :project => project, :name => "another version")
            feature.save
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => feature.id.to_s,
                                                                :status_id => status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)
          end

          it_should_behave_like "impediment creation with no blocking relationship"
          it { @impediment.should be_new_record }
          it { @impediment.errors[:blocks_ids].should include I18n.t(:can_only_contain_work_packages_of_current_sprint, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end

        describe "WITH the story being non existent" do
          before(:each) do
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => "0",
                                                                :status_id => status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)
          end

          it_should_behave_like "impediment creation with no blocking relationship"
          it { @impediment.should be_new_record }
          it { @impediment.errors[:blocks_ids].should include I18n.t(:can_only_contain_work_packages_of_current_sprint, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end
      end

      describe "WITHOUT a blocking relationship defined" do
        before(:each) do
          @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                              :assigned_to_id => user.id,
                                                              :blocks_ids => "",
                                                              :status_id => status1.id,
                                                              :fixed_version_id => version.id},
                                                              project.id)
        end

        it_should_behave_like "impediment creation with no blocking relationship"
        it { @impediment.should be_new_record }
        it { @impediment.errors[:blocks_ids].should include I18n.t(:must_block_at_least_one_work_package, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
      end
    end
  end

  describe "instance methods" do
    describe :update_with_relationships do
      before(:each) do
        role.permissions = [:update_impediments]
        role.save

        feature.fixed_version = version
        feature.save

        @impediment = impediment
        @impediment.blocks_ids = feature.id.to_s
        @impediment.save
      end

      shared_examples_for "impediment update" do
        it { @impediment.author.should eql user }
        it { @impediment.project.should eql project }
        it { @impediment.fixed_version.should eql version }
        it { @impediment.priority.should eql issue_priority}
        it { @impediment.status.should eql status1 }
        it { @impediment.type.should eql type_task }
        it { @impediment.blocks_ids.should eql @blocks.split(/\D+/).map{|id| id.to_i} }
      end

      shared_examples_for "impediment update with changed blocking relationship" do
        it_should_behave_like "impediment update"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].should_not be_new_record }
        it { @impediment.relations_from[0].to.should eql @story }
        it { @impediment.relations_from[0].relation_type.should eql Relation::TYPE_BLOCKS }
      end

      shared_examples_for "impediment update with unchanged blocking relationship" do
        it_should_behave_like "impediment update"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].should_not be_changed }
        it { @impediment.relations_from[0].to.should eql feature }
        it { @impediment.relations_from[0].relation_type.should eql Relation::TYPE_BLOCKS }
      end

      describe "WHEN changing the blocking relationship to another story" do
        before(:each) do
          @story = FactoryGirl.build(:work_package, :subject => "another story",
                                         :type => type_feature,
                                         :project => project,
                                         :author => user,
                                         :priority => issue_priority,
                                         :status => status1)
        end

        describe "WITH the story having the same version" do
          before(:each) do
            @story.fixed_version = version
            @story.save
            @blocks = @story.id.to_s
            @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                   :status_id => status1.id.to_s})
          end

          it_should_behave_like "impediment update with changed blocking relationship"
          it { @impediment.should_not be_changed }
        end

        describe "WITH the story having another version" do
          before(:each) do
            @story.fixed_version = FactoryGirl.create(:version, :project => project, :name => "another version")
            @story.save
            @blocks = @story.id.to_s
            @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                            :status_id => status1.id.to_s})
          end

          it_should_behave_like "impediment update with unchanged blocking relationship"
          it "should not be saved successfully" do
            @saved.should be_false
          end
          it { @impediment.errors[:blocks_ids].should include I18n.t(:can_only_contain_work_packages_of_current_sprint, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end

        describe "WITH the story beeing non existent" do
          before(:each) do
            @blocks = "0"
            @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                            :status_id => status1.id.to_s})
          end

          it_should_behave_like "impediment update with unchanged blocking relationship"
          it "should not be saved successfully" do
            @saved.should be_false
          end
          it { @impediment.errors[:blocks_ids].should include I18n.t(:can_only_contain_work_packages_of_current_sprint, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
        end
      end

      describe "WITHOUT a blocking relationship defined" do
        before(:each) do
          @blocks = ""
          @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                          :status_id => status1.id.to_s})
        end

        it_should_behave_like "impediment update with unchanged blocking relationship"
        it "should not be saved successfully" do
          @saved.should be_false
        end

        it { @impediment.errors[:blocks_ids].should include I18n.t(:must_block_at_least_one_work_package, :scope => [:activerecord, :errors, :models, :work_package, :attributes, :blocks_ids]) }
      end
    end

    describe "blocks_ids=/blocks_ids" do
      describe "WITH an integer" do
        it do
          impediment.blocks_ids = 2
          impediment.blocks_ids.should eql [2]
        end
      end

      describe "WITH a string" do
        it do
          impediment.blocks_ids = "1, 2, 3"
          impediment.blocks_ids.should eql [1,2,3]
        end
      end

      describe "WITH an array" do
        it do
          impediment.blocks_ids = [1,2,3]
          impediment.blocks_ids.should eql [1,2,3]
        end
      end

      describe "WITH only prior blockers defined" do
        before(:each) do
          feature.fixed_version = version
          feature.save
          task.fixed_version = version
          task.save

          impediment.relations_from = [Relation.new(:from => impediment, :to => feature, :relation_type => Relation::TYPE_BLOCKS),
                                       Relation.new(:from => impediment, :to => task, :relation_type => Relation::TYPE_BLOCKS)]
          true
        end

        it { impediment.blocks_ids.should eql [feature.id, task.id] }
      end
    end
  end
end
