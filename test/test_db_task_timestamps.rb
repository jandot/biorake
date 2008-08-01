#!/usr/bin/env ruby

require 'test/unit'
require '../lib/biorake'
require 'dbtaskcreation'
require 'yaml'

class TestDBTaskTimeStamp < Test::Unit::TestCase
  include Rake
  include DBTaskCreation

  def setup
    DBTask.clear
    @runs = Array.new
  end

  def test_names
    db :names_1
    db :names_2 => :names_1
    db_task_1 = DBTask[:names_1]
    db_task_2 = DBTask[:names_2]
    assert_equal 'names_1', db_task_1.name
    assert_equal 'names_2', db_task_2.name
  end
  
  def test_db_need
    name_1 = :db_need_1
    db name_1
    db_task = DBTask[name_1]
    assert_equal name_1.to_s, db_task.name

    name_2 = :db_need_2
    db name_2
    db_task = DBTask[name_2]
    assert db_task.needed?, 'task should be needed'
    Meta.new(:task => name_2.to_s).save
    assert_equal nil, db_task.prerequisites.collect{|n| DBTask[n].timestamp}.max
    assert ! db_task.needed?, "task should not be needed"
  end

  def test_task_times_new_depends_on_old
    create_timed_db_tasks(:old_task_times_new_depends_on_old, :new_task_times_new_depends_on_old)

    t1 = Rake.application.intern(DBTask, :new_task_times_new_depends_on_old).enhance([:old_task_times_new_depends_on_old])
    t2 = Rake.application.intern(DBTask, :old_task_times_new_depends_on_old)
    assert ! t2.needed?, "Should not need to build old task"
    assert ! t1.needed?, "Should not need to rebuild new task because of old"
  end
  
  def test_task_times_old_depends_on_new
    create_timed_db_tasks(:old_task_times_old_depends_on_new, :new_task_times_old_depends_on_new)
    
    t1 = Rake.application.intern(DBTask, :old_task_times_old_depends_on_new).enhance([:new_task_times_old_depends_on_new])
    t2 = Rake.application.intern(DBTask, :new_task_times_old_depends_on_new)
    assert ! t2.needed?, "Should not need to build new task"
    preq_stamp = t1.prerequisites.collect{|t| DBTask[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old task because of new"
  end

  def test_number_of_meta_entries
    create_timed_db_tasks(:old_number_of_meta_entries, :new_number_of_meta_entries)
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
    
    db :old_number_of_meta_entries => [:new_number_of_meta_entries] do |t| @runs << t.name end
    db :new_number_of_meta_entries do |t| @runs << t.name end
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
    
    t1 = Rake.application.intern(DBTask, :old_number_of_meta_entries).enhance([:new_number_of_meta_entries])
    t2 = Rake.application.intern(DBTask, :new_nmber_of_meta_entries)
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)

    DBTask[:old_number_of_meta_entries].invoke
    assert_equal(1, Meta.all(:task => 'old_number_of_meta_entries').length)
    assert_equal(1, Meta.all(:task => 'new_number_of_meta_entries').length)
  end

  def test_db_depends_on_task_depend_on_db
    create_timed_db_tasks(:old_db_depends_on_task_depend_on_db, :new_db_depends_on_task_depend_on_db)

    db :new_db_depends_on_task_depend_on_db => [:obj]   do |t| @runs << t.name end
    task :obj => [:old_db_depends_on_task_depend_on_db] do |t| @runs << t.name end
    db :old_db_depends_on_task_depend_on_db             do |t| @runs << t.name end

    Task[:obj].invoke
    DBTask[:new_db_depends_on_task_depend_on_db].invoke
    assert ! @runs.include?(:new_db_depends_on_task_depend_on_db)
  end

  def test_existing_db_task_depends_on_non_existing_db_task
    create_task(:old_existing_db_task_depends_on_non_existing_db_task)
    delete_task(:new_existing_db_task_depends_on_non_existing_db_task)
    db :new_existing_db_task_depends_on_non_existing_db_task
    db :old_existing_db_task_depends_on_non_existing_db_task => :new_existing_db_task_depends_on_non_existing_db_task
    assert_nothing_raised do DBTask[:old_existing_db_task_depends_on_non_existing_db_task].invoke end
  end
  
#  def teardown
#    Meta.all.each do |meta_record|
#      meta_record.destroy
#    end
#  end
end
