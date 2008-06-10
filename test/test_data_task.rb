#!/usr/bin/env ruby

require 'test/unit'
require '../lib/biorake'
require 'datataskcreation'

class TestDataTask < Test::Unit::TestCase
  include Rake
  include DataTaskCreation

  def setup
    Task.clear
  end

  def test_data_need
    name = "test"
    data name
    data_task = Task[name]
    assert_equal name.to_s, data_task.name

    name = 'data_manipulation_1'
    data name
    data_task = Task[name]
    assert data_task.needed?, 'task should be needed'
    Meta.new(:task => name).save!
    assert_equal nil, data_task.prerequisites.collect{|n| Task[n].timestamp}.max
    assert ! data_task.needed?, "task should not be needed"
    Meta.find_by_task(name).destroy
  end

  def test_task_times_new_depends_on_old
    create_timed_data_tasks('old_task','new_task')

    t1 = Rake.application.intern(DataTask, 'new_task').enhance(['old_task'])
    t2 = Rake.application.intern(DataTask, 'old_task')
    assert ! t2.needed?, "Should not need to build old task"
    assert ! t1.needed?, "Should not need to rebuild new task because of old"
    
    delete_task('old_task')
    delete_task('new_task')
  end
  
  def test_task_times_old_depends_on_new
    create_timed_data_tasks('old_task','new_task')
    
    t1 = Rake.application.intern(DataTask,'old_task').enhance(['new_task'])
    t2 = Rake.application.intern(DataTask,'new_task')
    assert ! t2.needed?, "Should not need to build new task"
    preq_stamp = t1.prerequisites.collect{|t| Task[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old task because of new"

    delete_task('old_task')
    delete_task('new_task')
  end

  
end
