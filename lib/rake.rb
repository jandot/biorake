#!/usr/bin/env ruby
require 'rake'

##############################################################################
module Rake

  # #########################################################################
  # A DataTask is a task that includes time based dependencies. Timestamps
  # are contained in a meta_rake table in the database. If any of a
  # DataTask's prerequisites have a timestamp that is later than the
  # represented by this task, then the file must be rebuilt (using the
  # supplied actions).
  #
  class DataTask < Task

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
  end # class Rake::DataTask

  # #########################################################################
  # A DataCreationTask is a data task that when used as a dependency will be
  # needed if and only if the data has not been created.  Once created, it is
  # not re-triggered if any of its dependencies are newer, nor does trigger
  # any rebuilds of tasks that depend on it whenever it is updated.
  #
  class DataCreationTask < DataTask
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
#   data :load_probes => [:load_individuals] do
#     File.open("my_file.txt").each do |line|
#       probe_name, individual_id = line.chomp.split(/\t/)
#       Probe.new(:name => probe_name, :individual_id => individual_id).new.save!
#     end
#   end
def data(*args, &block)
  Rake::DataTask.define_task(*args, &block)
end

# Declare a data creation task.
def data_create(args, &block)
  Rake::DataCreationTask.define_task(args, &block)
end
