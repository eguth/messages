require 'bundler/setup'
require 'rake/testtask'
load 'tasks/emoji.rake'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :default => :test
