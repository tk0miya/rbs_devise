# frozen_string_literal: true

require "rails"

module RbsDevise
  class InstallGenerator < ::Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_devise.rake", <<~RUBY
        begin
          require "rbs_devise/rake_task"
          RbsDevise::RakeTask.new
        rescue LoadError
          # failed to load rbs_devise. Skip to load rbs_devise tasks.
        end
      RUBY
    end
  end
end
