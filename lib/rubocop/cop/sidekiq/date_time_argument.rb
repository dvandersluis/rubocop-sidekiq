module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for date/time objects being passed as arguments to perform a Sidekiq
      # job. Dates, times, durations, and related classes cannot be serialized to Redis.
      # Use an integer or string representation of the date/time instead.
      #
      # By default, this only allows `to_i` and `to_s` as valid, serializable methods for these
      # classes. Use `AllowedMethods` to specify other allowed methods.
      #
      # @example
      #   # bad
      #   MyJob.perform_async(Time.now)
      #   MyJob.perform_async(Date.today)
      #   MyJob.perform_async(DateTime.now)
      #   MyJob.perform_async(ActiveSupport::TimeWithZone.new)
      #   MyJob.perform_async(1.hour)
      #   MyJob.perform_async(1.hour.ago)
      #
      #   # good
      #   MyJob.perform_async(Time.now.to_i)
      #   MyJob.perform_async(Date.today.to_s)
      #
      # @example AllowedMethods: [] (default)
      #   # bad
      #   MyJob.perform_async(Time.now.mday)
      #
      # @example AllowedMethods: ['mday']
      #   # good
      #   MyJob.perform_async(Time.now.mday)
      #
      class DateTimeArgument < ::RuboCop::Cop::Cop
        DURATION_METHODS = %i(
          second seconds
          minute minutes
          hour hours
          day days
          week weeks
          fortnight fortnights
        ).freeze

        DURATION_TO_TIME_METHODS = %i(
          from_now since after
          ago until before
        ).freeze

        include Helpers
        include RationalLiteral

        DURATION_MSG = 'Durations are not Sidekiq-serializable; use the integer instead.'.freeze
        MSG = 'Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.'.freeze
        ALLOWED_METHODS = %i(to_i to_s).freeze

        def_node_matcher :duration?, <<~PATTERN
          {
            (send {int float rational #rational_literal?} #duration_method?)
            (send (const (const _ :ActiveSupport) :Duration) ...)
          }
        PATTERN

        def_node_matcher :date_time_send?, <<~PATTERN
          $(send
            `{
              (const _ {:Date :DateTime :Time})
              (const (const _ :ActiveSupport) :TimeWithZone)
            }
            ...
          )
        PATTERN

        def_node_matcher :date_time_arg?, <<~PATTERN
          { #duration? #date_time_send? (send `#duration? #duration_to_time_method?) }
        PATTERN

        def on_send(node)
          sidekiq_arguments(node).each do |arg|
            next unless date_time_arg?(arg)
            next if node_approved?(arg)

            # If the outer send (ie. the last method in the chain) is in the allowed method
            # list, approve the node (so that sub chains aren't flagged).
            if allowed_methods.include?(arg.method_name)
              approve_node(arg)
              next
            end

            add_offense(arg)
          end
        end

        def allowed_methods
          Array(cop_config['AllowedMethods']).concat(ALLOWED_METHODS).map(&:to_sym)
        end

        def duration_method?(sym)
          DURATION_METHODS.include?(sym)
        end

        def duration_to_time_method?(sym)
          DURATION_TO_TIME_METHODS.include?(sym)
        end

        def message(node)
          return DURATION_MSG if duration?(node)
          super
        end
      end
    end
  end
end
