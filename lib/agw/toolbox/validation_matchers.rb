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

      class RequireFormatOf
        def initialize(attribute)
          @attribute = attribute
          @acceptable = []
          @rejectable = []
          @misses     = []
          @success    = true
        end

        def matches?(object)
          @object = object
          
          raise ArgumentError, 'need at least an acceptable or rejectable value' unless @acceptable.any? || @rejectable.any?
          
          try_values(@acceptable) do |value, error|
            fail! "#{@attribute} should accept #{value}" if error
          end
          
          try_values(@rejectable) do |value, error|
            if error
              unless correct_message_for(error)
                fail! "Expected error message to be #{@message}, but was #{@object.errors.on(@attribute)}"
              end
            else
              fail! "#{@attribute} should not accept #{value}"
            end
          end
          return @success
        end
        
        # Add a value that should be accepted
        def to_accept(value)
          only_with_a_string(value) { |value| @acceptable.push(value) }
        end
        alias_method :but_accept, :to_accept
        alias_method :and_accept, :to_accept
        
        # Add a value that should be rejected
        def to_reject(value)
          only_with_a_string(value) { |value| @rejectable.push(value) }
        end
        alias_method :and_reject, :to_reject
        alias_method :but_reject, :to_reject
        
        # Set the error message to test for
        def with(message)
          only_with_a_string(value) { |value| @message = message }
        end

        def failure_message
          "expected #{@object} to require format of #{@attribute.inspect}, but it didn't: #{@misses.to_yaml}"
        end

        def negative_failure_message
          "expected #{@object} not to require format of #{@attribute.inspect}, but it did: #{@misses.to_yaml}"
        end
        
        private
        
          # Make sure the passed in argument is a string. Raise an
          # arugment error if it is not. Yields the value and
          # returns self.
          def only_with_a_string(value)
            if value.is_a?(String)
              yield(value)
              return self
            else
              raise ArgumentError, 'only string values are accepted'
            end
          end
          
          # Try a series of values on our object for the given attribute
          # and yield the value and any errors on the attribute after validation          
          def try_values(values)
            values.each do |v|
              @object.send("#{@attribute}=", v)    # try to set the value
              @object.valid?
              yield(v, @object.errors.on(@attribute))
            end
          end
          
          # Let the match fail and register why it fails
          def fail!(msg = nil)
            @success = false
            @misses.push msg unless msg.nil?
          end
        
          # Check if the object has the right error message
          def correct_message_for(error)
            return true if @message.blank? || error.nil?
            
            if error.is_a?(String)
              return error == @message
            elsif error.is_a?(Array)
              return error.include?(@message)
            end
          end
      end

      # Test the format requirements of an AR model. This matcher lets
      # you specify values to test for acceptance or rejectment.
      #
      # Usage example:
      #
      #   @user.should require_format_of(:email).
      #     to_accept('mickey+stuff@mouse.com').
      #     but_reject('mickey**$@disney')
      #
      # All values will be tested and the failure message will tell you
      # where the matching went wrong.
      #
      # You can also test for the correct error message if you want to:
      #
      #   @user.should require_format_of(:url).
      #     to_reject('htt:/example.com').
      #     with('is not a valid URL')
      # 
      # You can chain multiple calls to reject or accept values. They both
      # come in `to_`, `but_` and `and_` forms.
      def require_format_of(attribute)
        RequireFormatOf.new(attribute)
      end
    end
  end
end