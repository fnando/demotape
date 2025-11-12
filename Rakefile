# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(test: :parser) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

task :parser do
  sh "racc demotape.y -o lib/demo_tape/parser.rb"
end

task default: %i[parser test rubocop]
