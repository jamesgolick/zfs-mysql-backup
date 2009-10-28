require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "zfs-mysql-backup"
    gem.summary = %Q{A script for backing up mysql databases using ZFS}
    gem.description = %Q{A script for backing up mysql databases using ZFS}
    gem.email = "james@giraffesoft.ca"
    gem.homepage = "http://github.com/giraffesoft/zfs-mysql-backup"
    gem.authors = ["James Golick"]
    gem.add_development_dependency "thoughtbot-shoulda"
    gem.add_dependency "thor"
    gem.add_dependency "activerecord"
    gem.add_dependency "aws-s3"
    gem.add_dependency "mysql"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "zfs-mysql-backup #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
