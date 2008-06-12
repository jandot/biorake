require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'biorake'
  s.version = "0.9"

  s.author = "Jan Aerts"
  s.email = "jan.aerts@gmail.com"
  s.homepage = "http://github.com/jandot/biorake"
  s.summary = "Extension to rake that keeps track of timestamps using a database"

  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,sample,test}/**/*")
  s.files.concat ["README.textile"]

  s.add_dependency('rake', '>=0.8.0')
  s.add_dependency('activerecord', '>=2.0.0')
  s.add_dependency('sqlite3-ruby', '>=1.2.0')
  
  s.require_path = 'lib'
  s.autorequire = 'biorake'
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
