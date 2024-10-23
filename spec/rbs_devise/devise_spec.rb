# frozen_string_literal: true

require "devise"
require "rbs_devise"

class User
end

class Account
end

RSpec.describe RbsDevise::Devise do
  describe ".available?" do
    subject { described_class.available? }

    context "When no devise mapping is defined" do
      before { allow(Devise).to receive(:mappings).and_return({}) }

      it { is_expected.to eq false }
    end

    context "When devise mapping is defined" do
      before { allow(Devise).to receive(:mappings).and_return({ user: User }) }

      it { is_expected.to eq true }
    end
  end

  describe ".generate" do
    subject { described_class.generate }

    context "When no devise mapping is defined" do
      before { allow(Devise).to receive(:mappings).and_return({}) }

      it { expect { subject }.to raise_error }
    end

    context "When devise mapping is defined" do
      before { allow(Devise).to receive(:mappings).and_return({ user: User }) }

      it "generates RBS" do
        is_expected.to eq <<~RBS
          module Devise
            module Controllers
              module SignInOut
                def signed_in?: (User | nil scope) -> bool

                def sign_in: (Symbol scope) -> void
                           | (User resource, **untyped options) -> void

                def bypass_sign_in: (User resource, ?scope: Symbol?) -> void

                def sign_out: (Symbol scope) -> bool
                            | (User resource) -> bool

                def sign_out_all_scopes: (?bool lock) -> bool
              end
            end

            module Helpers
              include Devise::Controllers::SignInOut

              def authenticate_user!: (?Hash[untyped, untyped] opts) -> void

              def user_signed_in?: () -> bool

              def current_user: () -> User

              def user_session: () -> untyped
            end

            module Models
              def devise: (*Symbol) -> void
            end

            class SessionsController < DeviseController
              def sign_in_params: () -> Hash[untyped, untyped]
            end
          end

          class DeviseController < ApplicationController
            def find_message: (String | Symbol kind, ?Hash[untyped, untyped] options) -> String
            def navigational_formats: () -> Array[Mime::Type]
            def resource: () -> User
            def resource=: (User) -> User
            def resource_class: () -> singleton(User)
            def resource_name: () -> Symbol
          end

          class ActionController::Base
            include Devise::Helpers
          end

          class ActiveRecord::Base
            extend Devise::Models
          end
        RBS
      end
    end

    context "When devise mapping has multiple definitions" do
      before { allow(Devise).to receive(:mappings).and_return({ user: User, account: Account }) }

      it "generates RBS" do
        is_expected.to eq <<~RBS
          module Devise
            module Controllers
              module SignInOut
                def signed_in?: (User | Account | nil scope) -> bool

                def sign_in: (Symbol scope) -> void
                           | (User | Account resource, **untyped options) -> void

                def bypass_sign_in: (User | Account resource, ?scope: Symbol?) -> void

                def sign_out: (Symbol scope) -> bool
                            | (User | Account resource) -> bool

                def sign_out_all_scopes: (?bool lock) -> bool
              end
            end

            module Helpers
              include Devise::Controllers::SignInOut

              def authenticate_user!: (?Hash[untyped, untyped] opts) -> void

              def user_signed_in?: () -> bool

              def current_user: () -> User

              def user_session: () -> untyped

              def authenticate_account!: (?Hash[untyped, untyped] opts) -> void

              def account_signed_in?: () -> bool

              def current_account: () -> Account

              def account_session: () -> untyped
            end

            module Models
              def devise: (*Symbol) -> void
            end

            class SessionsController < DeviseController
              def sign_in_params: () -> Hash[untyped, untyped]
            end
          end

          class DeviseController < ApplicationController
            def find_message: (String | Symbol kind, ?Hash[untyped, untyped] options) -> String
            def navigational_formats: () -> Array[Mime::Type]
            def resource: () -> (User | Account)
            def resource=: (User) -> User
                         | (Account) -> Account
            def resource_class: () -> (singleton(User) | singleton(Account))
            def resource_name: () -> Symbol
          end

          class ActionController::Base
            include Devise::Helpers
          end

          class ActiveRecord::Base
            extend Devise::Models
          end
        RBS
      end
    end
  end
end
