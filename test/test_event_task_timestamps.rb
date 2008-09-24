#!/usr/bin/env ruby

require 'test/unit'
require '../lib/biorake'
require 'event_task_creation'
require 'yaml'

class TestEventTaskTimeStamp < Test::Unit::TestCase
  include Rake
  include EventTaskCreation

  def setup
    EventTask.clear
    @runs = Array.new
  end

  def test_names
    event :names_1
    event :names_2 => :names_1
    event_task_1 = EventTask[:names_1]
    event_task_2 = EventTask[:names_2]
    assert_equal 'names_1', event_task_1.name
    assert_equal 'names_2', event_task_2.name
  end
  
  def test_event_need
    name_1 = :event_need_1
    event name_1
    event_task = EventTask[name_1]
    assert_equal name_1.to_s, event_task.name

    name_2 = :event_need_2
    event name_2
    event_task = EventTask[name_2]
    assert event_task.needed?, 'task should be needed'

    EventTask.touch(name_2.to_s)
    assert_equal nil, event_task.prerequisites.collect{|n| EventTask[n].timestamp}.max
    assert ! event_task.needed?, "task should not be needed"
  end

  def test_task_times_new_depends_on_old
    create_timed_event_tasks(:old_task_times_new_depends_on_old, :new_task_times_new_depends_on_old)

    t1 = Rake.application.intern(EventTask, :new_task_times_new_depends_on_old).enhance([:old_task_times_new_depends_on_old])
    t2 = Rake.application.intern(EventTask, :old_task_times_new_depends_on_old)
    assert ! t2.needed?, "Should not need to build old task"
    assert ! t1.needed?, "Should not need to rebuild new task because of old"
  end
  
  def test_task_times_old_depends_on_new
    create_timed_event_tasks(:old_task_times_old_depends_on_new, :new_task_times_old_depends_on_new)
    
    t1 = Rake.application.intern(EventTask, :old_task_times_old_depends_on_new).enhance([:new_task_times_old_depends_on_new])
    t2 = Rake.application.intern(EventTask, :new_task_times_old_depends_on_new)
    assert ! t2.needed?, "Should not need to build new task"
    preq_stamp = t1.prerequisites.collect{|t| EventTask[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old task because of new"
  end

  def test_event_depends_on_task_depend_on_data
    create_timed_event_tasks(:old_event_depends_on_task_depend_on_event, :new_event_depends_on_task_depend_on_event)

    event :new_event_depends_on_task_depend_on_event => [:obj]   do |t| @runs << t.name end
    task :obj => [:old_event_depends_on_task_depend_on_event] do |t| @runs << t.name end
    event :old_event_depends_on_task_depend_on_event             do |t| @runs << t.name end

    Task[:obj].invoke
    EventTask[:new_event_depends_on_task_depend_on_event].invoke
    assert ! @runs.include?(:new_event_depends_on_task_depend_on_event)
  end

  def test_existing_event_task_depends_on_non_existing_event_task
    create_task(:old_existing_event_task_depends_on_non_existing_event_task)
    delete_task(:new_existing_event_task_depends_on_non_existing_event_task)
    event :new_existing_event_task_depends_on_non_existing_event_task
    event :old_existing_event_task_depends_on_non_existing_event_task => :new_existing_event_task_depends_on_non_existing_event_task
    assert_nothing_raised do EventTask[:old_existing_event_task_depends_on_non_existing_event_task].invoke end
  end
  
  def teardown
    EventTask.clean
  end
end
