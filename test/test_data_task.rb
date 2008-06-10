#!/usr/bin/env ruby

require 'test/unit'
require '../lib/rake'
require 'activerecord'
require 'yaml'

######################################################################

class Meta < ActiveRecord::Base
  set_table_name 'meta'
end

class TestDataTask < Test::Unit::TestCase
  include Rake

  def setup
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => 'biorake.sqlite3'
    )

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

end
