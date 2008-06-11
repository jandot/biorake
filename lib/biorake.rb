#!/usr/bin/env ruby
require 'rubygems'
require 'rake'
require 'activerecord'

#######################################################
# Connection to database that contains task timestamps
#######################################################

class BioRakeConnection < ActiveRecord::Base
  self.abstract_class = true
  
  establish_connection(
    :adapter => 'sqlite3',
    :database => 'biorake.sqlite3'
  )
end

class Meta < BioRakeConnection
  set_table_name 'meta'
  
  def self.exist?(name)
    if Meta.find_by_task(name).nil?
      return false
    else
      return true
    end
  end
end

##########################
# Extension of rake
##########################

module Rake

  # #########################################################################
  # A DBTask is a task that includes time based dependencies. Timestamps
  # are contained in a meta_rake table in the database. If any of a
  # DataTask's prerequisites have a timestamp that is later than the
  # represented by this task, then the file must be rebuilt (using the
  # supplied actions).
  #
  class DBTask < Task

    # Is this data task needed?  Yes if it doesn't exist, or if its time stamp
    # is out of date.
    def needed?
      meta_record = Meta.find_by_task(name)
      return true if meta_record.nil?
      return true if out_of_date?(timestamp)
      false
    end

    # Time stamp for data task.
    def timestamp
      meta_record = Meta.find_by_task(name)
      if ! meta_record.nil?
        meta_record.updated_at
      else
        Rake::EARLY
      end
    end

    private

    # Are there any prerequisites with a later time than the given time stamp?
    def out_of_date?(stamp)
      @prerequisites.any? { |n| application[n].timestamp > stamp}
    end

    # ----------------------------------------------------------------
    # Task class methods.
    #
    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        task_name
      end
    end
  end # class Rake::DBTask

  # #########################################################################
  # A DataCreationTask is a data task that when used as a dependency will be
  # needed if and only if the data has not been created.  Once created, it is
  # not re-triggered if any of its dependencies are newer, nor does trigger
  # any rebuilds of tasks that depend on it whenever it is updated.
  #
  class DBCreationTask < DBTask
    # Is this data task needed?  Yes if it doesn't exist.
    def needed?
      Meta.find_by_task(name).nil?
    end

    # Time stamp for data creation task.  This time stamp is earlier
    # than any other time stamp.
    def timestamp
      Rake::EARLY
    end
  end
end

# Declare a data task.
#
# Example:
#   db :load_probes => [:load_individuals] do
#     File.open("my_file.txt").each do |line|
#       probe_name, individual_id = line.chomp.split(/\t/)
#       Probe.new(:name => probe_name, :individual_id => individual_id).new.save!
#     end
#   end
def db(*args, &block)
  task = Rake::DBTask.define_task(*args, &block)

  meta_record = Meta.find_by_task(task.name)
  if meta_record.nil?
    meta_record = Meta.new(:task => task.name)
    meta_record.save!
  end

  return task
end

## Declare a data creation task.
#def db_create(args, &block)
#  Rake::DBCreationTask.define_task(args, &block)
#    
##  meta_record = Meta.find_by_task(args.to_s)
##  if meta_record.nil?
##    meta_record = Meta.new(:task => args.to_s)
##    meta_record.save!
##  end
#end
