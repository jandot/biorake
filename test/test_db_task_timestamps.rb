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
    @task_names = Array.new
    @runs = Array.new
  end

  def test_names
    @task_names.push(:task_1)
    @task_names.push(:task_2)
    db :task_1
    db :task_2 => :task_1
    db_task_1 = DBTask[:task_1]
    db_task_2 = DBTask[:task_2]
    assert_equal 'task_1', db_task_1.name
    assert_equal 'task_2', db_task_2.name
  end
  
  def test_db_need
    @task_names.push(:test)
    name = :test
    db name
    db_task = DBTask[name]
    assert_equal name.to_s, db_task.name

    @task_names.push(:db_manipulation_1)
    name = :db_manipulation_1
    db name
    db_task = DBTask[name]
    assert db_task.needed?, 'task should be needed'
    Meta.new(:task => name.to_s).save!
    assert_equal nil, db_task.prerequisites.collect{|n| DBTask[n].timestamp}.max
    assert ! db_task.needed?, "task should not be needed"
  end

  def test_task_times_new_depends_on_old
    @task_names.push(:old_task1, :new_task_1)
    create_timed_db_tasks(:old_task1, :new_task1)

    t1 = Rake.application.intern(DBTask, :new_task1).enhance([:old_task1])
    t2 = Rake.application.intern(DBTask, :old_task1)
    assert ! t2.needed?, "Should not need to build old task"
    assert ! t1.needed?, "Should not need to rebuild new task because of old"
  end
  
  def test_task_times_old_depends_on_new
    @task_names.push(:old_task2, :new_task_2)
    create_timed_db_tasks(:old_task2, :new_task2)
    
    t1 = Rake.application.intern(DBTask, :old_task2).enhance([:new_task2])
    t2 = Rake.application.intern(DBTask, :new_task2)
    assert ! t2.needed?, "Should not need to build new task"
    preq_stamp = t1.prerequisites.collect{|t| DBTask[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old task because of new"
  end

  def test_db_depends_on_task_depend_on_db
    @task_names.push(:old_task3, :new_task_3)
    create_timed_db_tasks(:old_task3, :new_task3)

    db :new_task3 => [:obj]   do |t| @runs << t.name end
    task :obj => [:old_task3] do |t| @runs << t.name end
    db :old_task3             do |t| @runs << t.name end

    Task[:obj].invoke
    DBTask[:new_task3].invoke
    assert ! @runs.include?(:new_task3)
  end

  def test_existing_db_task_depends_on_non_existing_db_task
    @task_names.push(:old_task4, :new_task_4)

    create_task(:old_task4)
    delete_task(:new_task4)
    db :new_task4
    db :old_task4 => :new_task4
    assert_nothing_raised do DBTask[:old_task4].invoke end
  end
  
  def destroy
    @task_names.each do |name|
      delete_task(name)
    end
  end
end
