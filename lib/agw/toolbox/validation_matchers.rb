module AGW #:nodoc:
  module Toolbox #:nodoc:
    module ValidationMatchers
      class RequireA #:nodoc:
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.send("#{@expected}=", nil)
          @target.valid?
          if @message
            @target.errors.on(@expected) == @message
          else
            @target.errors.on(@expected) == ActiveRecord::Errors.default_error_messages[:blank]
          end
        end

        def with_message(message)
          @message = message
          self
        end

        def failure_message
          "expected #{@target.inspect} to require presence of #{@expected}"
        end

        def negative_failure_message
          "expected #{@target.inspect} not to require presence of #{expected}"
        end
      end

      def require_a(expected)
        RequireA.new(expected)
      end
      alias_method :require_an, :require_a

      class LimitSizeOf #:nodoc:
        def initialize(expected)
          @field = expected
        end

        def matches?(model)
          setup_errors
          @model = model
    
          @too_short = true
          if @range.begin > 0
            @model.send("#{@field}=", '.')
            @too_short = invalidates_correctly?
          end
    
          @model.send("#{@field}=", 'too long'.ljust(@range.end + 10, '.'))
          @too_long = invalidates_correctly?
    
          return @too_long && @too_short
        end
  
        def with_message(message)
          @message = message
          self
        end

        def to(limits)
          @limits = limits
          @range = limits.instance_of?(Range) ? limits : Range.new(0, limits.to_i)
          self
        end

        def failure_message
          output = "expected #{@model.inspect} to limit size of #{@field} to #{@range}.\n"
          output << "Expected one of the following error messages:\n"
          for error in @error_messages
            output << "  #{error}\n"
          end
          output << "but was\n  #{@model.errors.on(@field)}"
        end

        def negative_failure_message
          "expected #{@model.inspect} not to limit size of #{@field} to #{@range} (#{@too_short}, #{@too_long})"
        end 

        private 
  
          def setup_errors
            @limits = @limits.end if @limits.is_a?(Range)
            @error_messages = []
            @error_messages << ActiveRecord::Errors.default_error_messages[:wrong_length] % @limits
            @error_messages << ActiveRecord::Errors.default_error_messages[:too_long] % @range.end
            @error_messages << ActiveRecord::Errors.default_error_messages[:too_short] % @range.begin
          end
  
          def invalidates_correctly?
            @model.valid?
            if @message
              @model.errors.on(@field).include?(@message)
            elsif @model.errors.on(@field).is_a?(Array)
              (@error_messages & @model.errors.on(@field)).any?
            else
              @error_messages.include?(@model.errors.on(@field))
            end
          end
      end

      def limit_size_of(expected)
        LimitSizeOf.new(expected)
      end
      alias_method :limit_length_of, :limit_size_of

      class RequireNumericalityOf #:nodoc:
        def initialize(attribute)
          @attribute = attribute
        end
  
        def matches?(target)
          @target = target
    
          @valid_before = @target.valid?
          #return false unless @valid_before
    
          @target.send("#{@attribute}=", 'my value')
          @valid_after = @target.valid?
    
          @error = @target.errors.on(@attribute)
          @msg   = @error.include?(ActiveRecord::Errors.default_error_messages[:not_a_number]) if @error
    
          return @error && @msg
        end
  
        def with_message(msg)
          @message = msg
        end
  
        def failure_message
          if !@valid_before
            "expected #{@target.inspect} to be valid to begin with (#{@target.errors.inspect})"
          elsif !@error
            "expected #{@target.inspect} to call an error on #{@attribute} when given a non-number"
          elsif !@msg
            "expected #{@target.inspect} to call error 'is not a number' on #{@attribute} when given a non-number"
          end
        end

        def negative_failure_message
          "expected #{@target.inspect} not to call an error on #{@attribute} when given a non-number"
        end
      end

      def require_numericality_of(attribute)
        RequireNumericalityOf.new(attribute)
      end

      class RequireInclusionOf #:nodoc:
        def initialize(attribute)
          @attribute = attribute
        end
  
        def matches?(object)
          @object = object
          return try_value(@range.min - 1) && try_value(@range.max + 1)
        end
  
        def in(range)
          raise ArgumentError, 'expected a range' unless range.is_a?(Range)
          @range = range
          self
        end

        def failure_message
          "expected #{@object.inspect} to require #{@attribute} to be in #{@range}"
        end

        def negative_failure_message
          "expected #{@object.inspect} not to require #{@attribute} to be in #{@range}"
        end

        private
    
          def try_value(val)
            @object.send("#{@attribute}=", val)
            @object.valid?
            return @object.errors.on(@attribute) && @object.errors.on(@attribute).include?(ActiveRecord::Errors.default_error_messages[:inclusion])
          end
      end

      def require_inclusion_of(attribute)
        RequireInclusionOf.new(attribute)
      end
    end
  end
end