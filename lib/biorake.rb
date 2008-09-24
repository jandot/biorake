#!/usr/bin/env ruby
require 'rubygems'
require 'rake'
require 'dm-core'
require 'dm-timestamps'

#######################################################
# Connection to database that contains task timestamps
#######################################################

DataMapper.setup(:meta, 'sqlite3:biorake.sqlite3')

class Meta
  include DataMapper::Resource
  
  storage_names[:meta] = 'meta'
  
  property :id,         Integer,   :serial => true
  property :task,       String
  property :updated_at, Time
  
  def self.default_repository_name
    :meta
  end
  
  def self.exist?(name)
    !Meta.first(:task => name.to_s).nil?
  end
end

Meta.auto_migrate! if ! File.exists?('biorake.sqlite3')

##########################
# Extension of rake
##########################

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
      meta_record = Meta.first(:task => @name.to_s)
      return true if meta_record.nil?
      return true if out_of_date?(meta_record.updated_at)
      false
    end

    # Time stamp for data task.
    def timestamp      
      if(meta_record = Meta.first(:task => @name.to_s))
        meta_record.updated_at
      else
        Rake::EARLY
      end
    end

    def execute(args=nil)
      super(args)
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
  end # class Rake::DataTask
end

# Declare a data task.
#
# Example:
#   data :load_probes => [:load_individuals] do
#     File.open("my_file.txt").each do |line|
#       probe_name, individual_id = line.chomp.split(/\t/)
#       Probe.new(:name => probe_name, :individual_id => individual_id).new.save
#     end
#   end
def data(*args, &block)
  Rake::DataTask.define_task(*args, &block)
end

