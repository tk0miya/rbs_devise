# frozen_string_literal: true

require "rake/tasklib"

module RbsDevise
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :signature_root_dir

    def initialize(name = :"rbs:devise", &block)
      super()

      @name = name
      @signature_root_dir = Rails.root / "sig/devise"

      block&.call(self)

      define_generate_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_devise"

      deps = [:"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task
      desc "Generate a RBS file for Devise"
      task("#{name}:generate": :environment) do
        require "rbs_devise"  # load RbsDevise lazily

        return unless RbsDevise::Devise.available?

        signature_root_dir.mkpath
        (signature_root_dir / "devise.rbs").write RbsDevise::Devise.generate
      end
    end
  end
end
