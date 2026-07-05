# frozen_string_literal: true

require "rake/tasklib"

module RbsDevise
  class RakeTask < Rake::TaskLib
    attr_accessor :name #: Symbol
    attr_accessor :signature_root_dir #: Pathname

    # @rbs name: Symbol
    # @rbs &block: (RakeTask) -> void
    def initialize(name = :"rbs:devise", &block) #: void
      super()

      @name = name
      @signature_root_dir = Rails.root / "sig/devise"

      block&.call(self)

      define_generate_task
      define_setup_task
    end

    def define_setup_task #: void
      desc "Run all tasks of rbs_devise"

      deps = [:"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task #: void
      desc "Generate a RBS file for Devise"
      task("#{name}:generate": :environment) do
        require "rbs_devise" # load RbsDevise lazily

        next unless RbsDevise::Devise.available?

        signature_root_dir.mkpath
        (signature_root_dir / "devise.rbs").write RbsDevise::Devise.generate
      end
    end
  end
end
