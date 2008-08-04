#!/usr/bin/env ruby

require 'test/unit'
require '../lib/biorake'
require 'datataskcreation'
require 'yaml'

class TestDataTaskTimeStamp < Test::Unit::TestCase
  include Rake
  include DataTaskCreation

  def setup
    DataTask.clear
    @runs = Array.new
  end

  def test_names
    data :names_1
    data :names_2 => :names_1
    data_task_1 = DataTask[:names_1]
    data_task_2 = DataTask[:names_2]
    assert_equal 'names_1', data_task_1.name
    assert_equal 'names_2', data_task_2.name
  end
  
  def test_data_need
    name_1 = :data_need_1
    data name_1
    data_task = DataTask[name_1]
    assert_equal name_1.to_s, data_task.name

    name_2 = :data_need_2
    data name_2
    data_task = DataTask[name_2]
    assert data_task.needed?, 'task should be needed'
    Meta.new(:task => name_2.to_s).save
    assert_equal nil, data_task.prerequisites.collect{|n| DataTask[n].timestamp}.max
    assert ! data_task.needed?, "task should not be needed"
  end

  def test_task_times_new_depends_on_old
    create_timed_data_tasks(:old_task_times_new_depends_on_old, :new_task_times_new_depends_on_old)

    t1 = Rake.application.intern(DataTask, :new_task_times_new_depends_on_old).enhance([:old_task_times_new_depends_on_old])
    t2 = Rake.application.intern(DataTask, :old_task_times_new_depends_on_old)
    assert ! t2.needed?, "Should not need to build old task"
    assert ! t1.needed?, "Should not need to rebuild new task because of old"
  end
  
  def test_task_times_old_depends_on_new
    create_timed_data_tasks(:old_task_times_old_depends_on_new, :new_task_times_old_depends_on_new)
    
    t1 = Rake.application.intern(DataTask, :old_task_times_old_depends_on_new).enhance([:new_task_times_old_depends_on_new])
    t2 = Rake.application.intern(DataTask, :new_task_times_old_depends_on_new)
    assert ! t2.needed?, "Should not need to build new task"
    preq_stamp = t1.prerequisites.collect{|t| DataTask[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old task because of new"
  end

  def test_number_of_meta_entries
    create_timed_data_tasks(:old_number_of_meta_entries, :new_number_of_meta_entries)
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
    
    data :old_number_of_meta_entries => [:new_number_of_meta_entries] do |t| @runs << t.name end
    data :new_number_of_meta_entries do |t| @runs << t.name end
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
    
    t1 = Rake.application.intern(DataTask, :old_number_of_meta_entries).enhance([:new_number_of_meta_entries])
    t2 = Rake.application.intern(DataTask, :new_nmber_of_meta_entries)
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)

    DataTask[:old_number_of_meta_entries].invoke
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
  end

  def test_data_depends_on_task_depend_on_data
    create_timed_data_tasks(:old_data_depends_on_task_depend_on_data, :new_data_depends_on_task_depend_on_data)

    data :new_data_depends_on_task_depend_on_data => [:obj]   do |t| @runs << t.name end
    task :obj => [:old_data_depends_on_task_depend_on_data] do |t| @runs << t.name end
    data :old_data_depends_on_task_depend_on_data             do |t| @runs << t.name end

    Task[:obj].invoke
    DataTask[:new_data_depends_on_task_depend_on_data].invoke
    assert ! @runs.include?(:new_data_depends_on_task_depend_on_data)
  end

  def test_existing_data_task_depends_on_non_existing_data_task
    create_task(:old_existing_data_task_depends_on_non_existing_data_task)
    delete_task(:new_existing_data_task_depends_on_non_existing_data_task)
    data :new_existing_data_task_depends_on_non_existing_data_task
    data :old_existing_data_task_depends_on_non_existing_data_task => :new_existing_data_task_depends_on_non_existing_data_task
    assert_nothing_raised do DataTask[:old_existing_data_task_depends_on_non_existing_data_task].invoke end
  end
  
  def teardown
    Meta.all.each do |meta_record|
      meta_record.destroy
    end
  end
end
