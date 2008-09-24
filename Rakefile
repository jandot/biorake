task :default => :test

desc "Run all the tests"
task :test do
  Dir.chdir("test") do
    ruby "test_event_task.rb"
    ruby "test_event_task_timestamps.rb"
    ruby "test_event_task_with_file.rb"
  end
end
