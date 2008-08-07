Gem::Specification.new do |s|
  s.name = 'biorake'
  s.version = "0.1"
 
  s.author = "Jan Aerts"
  s.email = "jan.aerts at gmail.com"
  s.homepage = "http://github.com/jandot/biorake"
  s.summary = "Extension to rake to allow for timestamp usage on data in database"
  s.description = "Extension to rake to allow for timestamp usage on data in database"
 
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,sample,test}/**/*")
  s.files.concat ["README.textile"]
 
  s.add_dependency('rake')
  s.add_dependency('dm-core', '>=0.9.3')
  s.add_dependency('dm-timestamps', '>=0.9.3')
  
  s.has_rdoc = false
  
  s.test_files = Dir.glob('test/test_*.rb')
  
  s.require_path = 'lib'
  s.autorequire = 'rake'
 
end