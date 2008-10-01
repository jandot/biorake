require 'rubygems'
require 'rake'

module Rake

  # #########################################################################
  # An EventTask is a task that includes time based dependencies with no
  # associated file. Timestamps are contained in the .rake
  # directory. If any of a DataTask's prerequisites have a timestamp
  # that is later than the represented by this task, then the file
  # must be rebuilt (using the supplied actions).
  #
  class EventTask < FileTask

    # Is this data task needed?  Yes if it doesn't exist, or if its time stamp
    # is out of date.
    def needed?
      return true if !File.exist?(taskfn)
      return true if out_of_date?(timestamp)
      false
    end

    # Time stamp for data task.
    def timestamp      
      if(File.exist?(taskfn))
        File.mtime(taskfn)
      else
        Rake::EARLY
      end
    end

    def execute(args=nil)
      super(args)
      # And save the timestamp in storage
      EventTask.touch(name.to_s)
    end

    private

    def taskfn
      ".rake/"+name.to_s
    end

    # ----------------------------------------------------------------
    # Task class methods.
    #
    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        (scope + [task_name]).join(':')
      end

      def touch(fn)
        FileUtils.mkdir_p ".rake"
        FileUtils.touch ".rake/#{fn}"
      end

      def clean
        FileUtils.rm_rf ".rake"
      end
    end
  end # class Rake::EventTask
end

# Declare an event task.
#
# Example:
#   event :load_probes => [:load_individuals] do
#     File.open("my_file.txt").each do |line|
#       probe_name, individual_id = line.chomp.split(/\t/)
#       Probe.new(:name => probe_name, :individual_id => individual_id).new.save
#     end
#   end
def event(*args, &block)
  Rake::EventTask.define_task(*args, &block)
end
