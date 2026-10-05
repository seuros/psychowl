# frozen_string_literal: true

module Psychowl
  # Makes the `language:` validator available in Rails apps.
  class Railtie < Rails::Railtie
    initializer 'psychowl.active_model' do
      require 'psychowl/active_model'
    end
  end
end
