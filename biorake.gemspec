Gem::Specification.new do |s|
  s.name = 'biorake'
  s.version = "1.0"
 
  s.authors = ["Jan Aerts","Charles Comstock"]
  s.email = "jan.aerts at gmail.com"
  s.homepage = "http://github.com/jandot/biorake"
  s.summary = "Extension to rake to allow for timestamp usage on tasks that don't alter files"
  s.description = "Extension to rake to allow for timestamp usage on tasks that don't alter files (e.g. loading data in a database)"
 
  s.platform = Gem::Platform::RUBY
  s.files = [
      "biorake.gemspec",
      "lib/biorake.rb",
      "Rakefile",
      "README.textile",
      "sample/individuals.txt",
      "sample/intensities.txt",
      "sample/probes.txt",
      "sample/Rakefile",
      "test/capture_stdout.rb",
      "test/event_task_creation.rb",
      "test/file_creation.rb",
      "test/test_event_task.rb",
      "test/test_event_task_timestamps.rb",
      "test/test_event_task_with_file.rb"
    ]
 
  s.add_dependency('rake')
  
  s.has_rdoc = false
  
  s.test_files = [
      "test/test_event_task.rb",
      "test/test_event_task_timestamps.rb",
      "test/test_event_task_with_file.rb"
    ]
  
  s.require_path = 'lib'
  s.autorequire = 'rake'
 
end