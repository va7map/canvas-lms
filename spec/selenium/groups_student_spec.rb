require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe "student groups" do
  include_examples "in-process server selenium tests"
  let(:group_name){ 'Windfury' }
  let(:group_category_name){ 'cat1' }

  describe "as a student" do


    before(:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should allow student group leaders to edit the group name", priority:"1", test_id:180670 do
      category1 = @course.group_categories.create!(:name => "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(:name => "some group", :group_category => category1)

      g1.add_user @student
      g1.leader = @student
      g1.save!

      get "/groups/#{g1.id}"

      keep_trying_until do
        f('#edit_group').click
        set_value f('#group_name'), "new group name"
        f('#ui-id-2').find_element(:css, 'button[type=submit]').click
        wait_for_ajaximations
      end

      expect(g1.reload.name).to eq "new group name"
    end

    it "should show locked student organized, invite only groups", priority:"1", test_id:180671 do
      @course.groups.create!(:name => "my group")
      get "/courses/#{@course.id}/groups"

      expect(f(".icon-lock")).to be_displayed
    end

    describe "new student group" do
      before(:each) do
        seed_users(5)
        get "/courses/#{@course.id}/groups"
        f(".icon-plus").click
        wait_for_ajaximations
      end

      it "should have dropdown with two options", priority:"2", test_id:180681 do
        expect(ff("#joinLevelSelect option").length).to eq 2
        expect(ff("#joinLevelSelect option")[0]).to include_text("Course members are free to join")
        expect(ff("#joinLevelSelect option")[1]).to include_text("Membership by invitation only")
      end

      it "should show students in the course", priority:"1", test_id:180675 do
        expected_student_list = ["Test Student 1", "Test Student 2", "Test Student 3",
                                 "Test Student 4", "Test Student 5"]
        student_list = ffj(".checkbox")

        # check the list of students for expected names
        student_list.each_with_index do |student, index|
          expect(student).to include_text(expected_student_list[index].to_s)
        end
      end

      it "should be titled what the user types in", priority:"1", test_id:180676 do
        create_default_student_group(group_name)

        expect(fj(".student-group-title")).to include_text(group_name.to_s)
      end

      it "by default, created student group only contains the student creator", priority:"2", test_id:180682 do
        create_default_student_group()

        # expand the group
        fj(".student-group-title").click
        wait_for_animations

        # first item in the array is the group name
        students = ff("[role=listitem]")
        expect(students.length).to eq 2
        expect(students[1]).to include_text("nobody@example.com")
      end

      it "should add students to the group", priority:"1", test_id:180677 do
        create_group_and_add_all_students

        # expand the group
        fj(".student-group-title").click
        wait_for_animations

        expected_student_list = ["nobody@example.com","Test Student 1","Test Student 2",
                                 "Test Student 3","Test Student 4","Test Student 5"]
        student_list = ff("[role=listitem]")

        # first item in the student_list array is the group name
        # I skip the group name and then do an index-1 to account for skipping index 0
        student_list.each_with_index do |student, index|
          if (index != 0)
            expect(student).to include_text(expected_student_list[index-1].to_s)
          end
        end
      end
    end

    describe "student group index page" do
      before(:each) do
        create_group_with_student(group_name:group_name)
        get "/courses/#{@course.id}/groups"
      end

      it "leaving a group should decrement student count", priority:"1", test_id:180678 do
        expect(f(".student-group-students")).to include_text("1 student")

        f(".student-group-join a").click
        wait_for_animations

        keep_trying_until {expect(f(".student-group-students")).to include_text("0 students") }
      end

      it "leaving the group should change the dialog to join", priority:"2", test_id:180683 do
        f(".student-group-join a").click
        wait_for_animations

        keep_trying_until { expect(f(".student-group-join a")).to include_text("JOIN") }
      end

      it "student should be able to leave a group and rejoin", priority:"1", test_id:180679 do
        # verify that you are in the group
        expect(f(".student-group-join a")).to include_text("LEAVE")

        # leave group and verify leaving
        f(".student-group-join a").click
        wait_for_animations
        keep_trying_until { expect(f(".student-group-join a")).to include_text("JOIN") }

        # rejoin group
        f(".student-group-join a").click
        wait_for_animations
        keep_trying_until { expect(f(".student-group-join a")).to include_text("LEAVE") }
      end

      it "should visit the group", priority:"1", test_id:180680 do
        fln('Visit').click
        wait_for_animations

        expect(f("#breadcrumbs")).to include_text(group_name.to_s)
      end

      it "student group leader can manage group", priority:"2", test_id:180702 do
        fln('Manage').click
        wait_for_animations

        expect(f(".ui-dialog-titlebar")).to include_text("Manage Student Group")
      end
    end

    describe "student who is not in the group", priority:"2", test_id:184465 do
      it "should allow the student to join a student group they did not create" do
        create_group_with_student(group_name:group_name,enroll_student_count:0,add_student:false)
        get "/courses/#{@course.id}/groups"

        # join group
        f(".student-group-join a").click
        wait_for_animations
        keep_trying_until { expect(f(".student-group-join a")).to include_text("LEAVE") }
      end
    end

    describe "Manage Student Group Page" do
      before(:each) do
        create_group_with_student(group_name:group_name, enroll_student_count:2)
        get "/courses/#{@course.id}/groups"
      end

      it "should populate dialog with current group name", priority:"2", test_id:180711 do
        fln('Manage').click
        wait_for_animations

        expect(f("#group_name")).to have_attribute(:value, group_name.to_s)
      end

      it "should change group name", priority:"2", test_id:180714 do
        fln('Manage').click
        wait_for_animations

        addition = "CRIT"
        f("#group_name").send_keys(addition.to_s)
        wait_for_animations
        fj('button.confirm-dialog-confirm-btn').click
        wait_for_animations

        new_group_name = group_name.to_s + addition.to_s
        keep_trying_until(3) {expect(fj(".student-group-title")).to include_text(new_group_name.to_s) }
      end

      it "should add users to group", priority:"1", test_id:180718 do
        # expand the group
        fj(".student-group-title").click
        wait_for_animations

        # verify that there is only one student
        # first item in the array is the group name
        students = ff("[role=listitem]")
        expect(students.length).to eq 2
        expect(students[1]).to include_text("nobody@example.com")

        fln('Manage').click
        wait_for_animations

        students = ffj(".checkbox")
        students.each do |student|
          student.click
        end

        fj('button.confirm-dialog-confirm-btn').click
        wait_for_animations

        expected_student_list = ["nobody@example.com","Test Student 1", "Test Student 2"]
        student_list = ff("[role=listitem]")

        # first item in the student_list array is the group name
        # I skip the group name and then do an index-1 to account for skipping index 0
        student_list.each_with_index do |student, index|
          if (index != 0)
            expect(student).to include_text(expected_student_list[index-1].to_s)
          end
        end
      end

      it "add/remove plurality to the word 'student' if one student", priority:"2", test_id:180723 do
        expect(f(".student-group-students")).to include_text("1 student")

        fln('Manage').click
        wait_for_ajaximations

        # add the first student that isn't the current student
        ffj(".checkbox:visible")[1].click
        wait_for_animations

        fj('button.confirm-dialog-confirm-btn').click
        wait_for_animations

        # expect plural of the word 'student'
        keep_trying_until(2) { expect(f(".student-group-students")).to include_text("students") }

        # leave the group
        fj(".student-group-join a").click
        wait_for_animations

        keep_trying_until(2) { expect(fj(".student-group-students")).to include_text("1 student") }
      end
    end
  end
end
