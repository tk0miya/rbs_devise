# frozen_string_literal: true

require "devise"
require "rbs"

module  RbsDevise
  module Devise
    def self.available? #: bool
      ::Devise.mappings.any?
    end

    def self.generate #: String
      raise unless available?

      Generator.new.generate
    end

    class Generator
      def generate #: String
        format <<~RBS
          module Devise
            #{devise_controllers_signinout_decl}
            #{device_helpers_decl}
            #{device_models_decl}
            #{devise_sessions_controller_decl}
          end

          #{devise_controller_decl}
          #{actioncontroller_base_decl}
          #{activerecord_base_decl}
        RBS
      end

      private

      # @rbs rbs: String
      def format(rbs) #: String
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      def devise_controllers_signinout_decl #: String
        resource_type = resource_classes.join(" | ")
        <<~RBS
          module Controllers
            module SignInOut
              def signed_in?: (#{resource_type} | nil scope) -> bool
              def sign_in: (Symbol scope) -> void
                        | (#{resource_type} resource, **untyped options) -> void
              def bypass_sign_in: (#{resource_type} resource, ?scope: Symbol?) -> void
              def sign_out: (Symbol scope) -> bool
                          | (#{resource_type} resource) -> bool
              def sign_out_all_scopes: (?bool lock) -> bool
            end
          end
        RBS
      end

      def device_helpers_decl #: String
        <<~RBS
          module Helpers
            include Devise::Controllers::SignInOut

            #{device_helpers_methods}
          end
        RBS
      end

      def device_helpers_methods #: String
        resource_classes.map do |klass_name|
          resource = klass_name.underscore
          <<~RBS.strip
            def authenticate_#{resource}!: (?Hash[untyped, untyped] opts) -> void
            def #{resource}_signed_in?: () -> bool
            def current_#{resource}: () -> #{klass_name}
            def #{resource}_session: () -> untyped
          RBS
        end.join("\n")
      end

      def device_models_decl #: String
        <<~RBS
          module Models
            def devise: (*Symbol) -> void
          end
        RBS
      end

      def devise_sessions_controller_decl #: String
        <<~RBS
          class SessionsController < DeviseController
            def sign_in_params: () -> Hash[untyped, untyped]
          end
        RBS
      end

      def devise_controller_decl #: String
        <<~RBS
          class DeviseController < #{parent_controller}
            def find_message: (String | Symbol kind, ?Hash[untyped, untyped] options) -> String
            def navigational_formats: () -> Array[Mime::Type]
            def resource: () -> (#{resource_classes.join(" | ")})
            def resource=: #{resource_classes.map { "(#{_1}) -> #{_1}" }.join(" | ")}
            def resource_class: () -> (#{resource_classes.map { "singleton(#{_1})" }.join(" | ")})
            def resource_name: () -> Symbol
          end
        RBS
      end

      def actioncontroller_base_decl #: String
        <<~RBS
          class ActionController::Base
            include Devise::Helpers
          end
        RBS
      end

      def activerecord_base_decl #: String
        <<~RBS
          class ActiveRecord::Base
            extend Devise::Models
          end
        RBS
      end

      def parent_controller #: String
        ::Devise.parent_controller
      end

      def resource_classes #: Array[String]
        ::Devise.mappings.keys.map(&:to_s).map(&:camelcase)
      end
    end
  end
end
