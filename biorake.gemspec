Gem::Specification.new do |s|
  s.name = 'biorake'
  s.version = "1.0"
 
  s.authors = ["Jan Aerts","Charles Comstock"]
  s.email = "jan.aerts at gmail.com"
  s.homepage = "http://github.com/jandot/biorake"
  s.summary = "Extension to rake to allow for timestamp usage on tasks that don't alter files"
  s.description = "Extension to rake to allow for timestamp usage on tasks that don't alter files (e.g. loading data in a database)"
 
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,sample,test}/**/*")
  s.files.concat ["README.textile"]
 
  s.add_dependency('rake')
  
  s.has_rdoc = false
  
  s.test_files = Dir.glob('test/test_*.rb')
  
  s.require_path = 'lib'
  s.autorequire = 'rake'
 
end