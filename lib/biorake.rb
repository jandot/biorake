#!/usr/bin/env ruby
require 'rubygems'
require 'rake'
require 'dm-core'
require 'dm-timestamps'

#######################################################
# Connection to database that contains task timestamps
#######################################################

DataMapper.setup(:default, 'sqlite3:biorake.sqlite3')

class Meta
  include DataMapper::Resource
  
  storage_names[:default] = 'meta'
  
  property :id,         Integer,   :serial => true
  property :task,       String
  property :updated_at, DateTime
  
  def self.exist?(name)
    if Meta.first(:task => name.to_s).nil?
      return false
    else
      return true
    end
  end
end
Meta.auto_migrate!

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
      meta_record = Meta.first(:task => @name.to_s)
      return true if meta_record.nil?
      return true if out_of_date?(timestamp)
      false
    end

    # Time stamp for data task.
    def timestamp
      meta_record = Meta.first(:task => @name.to_s)
      if ! meta_record.nil?
        meta_record.updated_at
      else
        Rake::EARLY
      end
    end

    def execute(args)
      if application.options.dryrun
        puts "** Execute (dry run) #{name.to_s}"
        return
      end
      if application.options.trace
        puts "** Execute #{name.to_s}"
      end
      application.enhance_with_matching_rule(name.to_s) if @actions.empty?
      @actions.each do |act|
        case act.arity
        when 1
          act.call(self)
        else
          act.call(self, args)
        end
      end
      
      # And save the timestamp in the database
      meta_record = Meta.first(:task => @name.to_s)
      if meta_record.nil?
        meta_record = Meta.new(:task => @name.to_s)
      end
      meta_record.save
    end

    private

    # Are there any prerequisites with a later time than the given time stamp?
    def out_of_date?(stamp)
      @prerequisites.any? { |n| application[n].timestamp > stamp}
    end

#    # ----------------------------------------------------------------
#    # Task class methods.
#    #
#    class << self
#      # Apply the scope to the task name according to the rules for this kind
#      # of task.  File based tasks ignore the scope when creating the name.
#      def scope_name(scope, task_name)
#        task_name
#      end
#    end
  end # class Rake::DBTask
end

# Declare a data task.
#
# Example:
#   db :load_probes => [:load_individuals] do
#     File.open("my_file.txt").each do |line|
#       probe_name, individual_id = line.chomp.split(/\t/)
#       Probe.new(:name => probe_name, :individual_id => individual_id).new.save
#     end
#   end
def db(*args, &block)
  Rake::DBTask.define_task(*args, &block)
end

