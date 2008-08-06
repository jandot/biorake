#!/usr/bin/env ruby
require 'pathname'

require 'test/unit'
#require 'fileutils'
require '../lib/biorake'
require 'filecreation.rb'
require 'capture_stdout.rb'
require 'datataskcreation'


module Interning
  private

  def data_intern(name, *args)
    Rake.application.define_task(Rake::DataTask, name, *args)
  end
  
  def file_intern(name, *args)
    Rake.application.define_task(Rake::FileTask, name, *args)
  end

end

######################################################################
class DataTestTask < Test::Unit::TestCase
  include CaptureStdout
  include Rake
  include Interning
  include DataTaskCreation

  def setup
    DataTask.clear
    FileTask.clear
  end

  def test_invoke
    runlist = []
    t1 = data_intern(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = file_intern(:t2).enhance { |t| runlist << t.name }
    t3 = data_intern(:t3).enhance { |t| runlist << t.name }
    assert_equal [:t2, :t3], t1.prerequisites
    t1.invoke
    assert_equal ["t2", "t3", "t1"], runlist
  end

  def test_invoke_with_circular_dependencies
    runlist = []
    t1 = data_intern(:t1).enhance([:t2]) { |t| runlist << t.name; 3321 }
    t2 = file_intern(:t2).enhance([:t1]) { |t| runlist << t.name }
    assert_equal [:t2], t1.prerequisites
    assert_equal [:t1], t2.prerequisites
    ex = assert_raise RuntimeError do
      t1.invoke
    end
    assert_match(/circular dependency/i, ex.message)
    assert_match(/t1 => t2 => t1/, ex.message)
  end

  def test_no_double_invoke
    runlist = []
    t1 = data_intern(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = data_intern(:t2).enhance([:t3]) { |t| runlist << t.name }
    t3 = data_intern(:t3).enhance { |t| runlist << t.name }
    t1.invoke
    assert_equal ["t3", "t2", "t1"], runlist
  end
  
  def teardown
    Meta.all.each do |meta_record|
      meta_record.destroy
    end
  end
end
