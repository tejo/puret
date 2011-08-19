require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require File.join(File.dirname(__FILE__), 'lib', 'puret', 'version')

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the puret plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the puret plugin.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Puret'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "puret"
    s.email = "schmidt@netzmerk.com"
    s.summary = "Pure model translations"
    s.homepage = "http://github.com/jo/puret"
    s.description = "Pure model translations"
    s.authors = ['Johannes Jorg Schmidt']
    s.files =  FileList["[A-Z]*(.rdoc)", "{generators,lib}/**/*", "init.rb"]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end

