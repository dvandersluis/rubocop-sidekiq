require 'rubocop'

require_relative 'rubocop/ast/node'

require_relative 'rubocop/sidekiq'
require_relative 'rubocop/sidekiq/version'
require_relative 'rubocop/sidekiq/inject'

RuboCop::Sidekiq::Inject.defaults!

require_relative 'rubocop/cop/sidekiq_cops'
