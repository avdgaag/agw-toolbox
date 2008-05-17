module AGW #:nodoc:
  module Toolbox #:nodoc:
    # This module provides custom matchers to be used
    # with the Rspec BDD-framework for Ruby.
    #
    # Author::    Arjan van der Gaag (info@agwebdesign.nl)
    # Copyright:: copyright (c) 2007 AG Webdesign
    # License::   distributed under the same terms as Ruby.
    module CustomMatchers

      class DeleteFile #:nodoc:
        def initialize(filename)
          @filename = filename
        end

        def matches?(block)
          raise ArgumentError, "File should exist: #{@filename}" unless File.exist?(@filename)
          block.call
          return !File.exist?(@filename)
        end

        def failure_message
          "Expected block to remove file #{@filename}"
        end

        def negative_failure_message
          "Expected block not to remove file #{@filename}"
        end
      end

      # See if calling a block removes a file from the file system.
      def delete_file(filename)
        DeleteFile.new(filename)
      end

      class CreateFile #:nodoc:
        def initialize(filename)
          @filename = filename
        end

        def matches?(block)
          block.call
          return File.exists?(@filename)
        end

        def failure_message
          "Expected block to generate file #{@filename}"
        end

        def negative_failure_message
          "Expected block not to generate file #{@filename}"
        end
      end

      # This matcher makes sure a given glock generates the file given
      # by `filename`.
      def create_file(filename)
        CreateFile.new(filename)
      end

      class RenderError #:nodoc:
        def initialize(code)
          @code = code
        end

        def matches?(target)
          @target = target
          @target.headers['Status'] =~ Regexp.new("#{@code}") && @target.rendered_file == "#{RAILS_ROOT}/public/#{@code}.html"
        end

        def failure_message
          "expected #{@target} to report #{@code} (rendered #{@target.rendered_file})"
        end

        def negative_failure_message
          "expected #{@target} not to report #{@code} (rendered #{@target.rendered_file})"
        end
      end

      # Match a response to rendering a 404 error.
      # This matcher checks if the response renders the
      # +/public/404.html+ page to the user and sends the
      # 404 header along with it.
      #
      # Usage example:
      #
      #   it 'should render 404' do
      #     get :show, :id => 999
      #     response.should render_missing
      #   end
      #
      def render_missing
        RenderError.new('404')
      end

      # Match a response to rendering a 422 error.
      # This matcher checks if the response renders the
      # +/public/422.html+ page to the user and sends the
      # 422 header along with it.
      #
      # Usage example:
      #
      #   it 'should render 422' do
      #     get :show, :id => 999
      #     response.should render_access_denied
      #   end
      #
      def render_access_denied
        RenderError.new('422')
      end

      class HaveLoggedInUser #:nodoc:
        def matches?(target)
          @target = target
          @explanation = @target.session.nil? ? 'session is nil' : 'session[:user_id] is ' + @target.session[:user_id].inspect
          !@target.session.nil? && !@target.session[:user_id].nil?
        end

        def failure_message
          "expected #{@target} to have session[:user] set, but it is nil (#{@explanation})"
        end

        def negative_failure_message
          "expected #{@target} not to have session[:user] set, but it does (#{@explanation})"
        end
      end

      # Make sure that a response has a logged in user;
      # that is: a user is logged in after making a request.
      #
      # Usage example:
      #
      #   it 'should should log in the user' do
      #     get :create, :login => 'quentin', :password => 'test'
      #     response.should have_logged_in_user
      #   end
      # 
      def have_logged_in_user
        HaveLoggedInUser.new
      end

      class PreventMassAssignmentOf #:nodoc:
        def initialize(attribute)
          @attribute = attribute
        end
  
        def matches?(object)
          @object = object
          @old_value = @object[@attribute]
    
          # determine a new value
          @new_value ||= case @old_value
            when nil: '100'
            when String: "a#{@old_value}"
            when Integer: @old_value + 1
            when Time: @old_value - 10
            when true: false
            when false: true
            else
              nil
          end
          raise "Could not determine a suitable replacement value for #{@old_value} with #{@attribute}" if @old_value == @new_value
    
          # update the attributes
          @object.update_attributes(@object.attributes.merge(@attribute => @new_value))
    
          # return whether the attribute has changed
          return @object[@attribute] != @new_value
        end

        # provide a value to test against
        def with(new_value)
          @new_value = new_value
        end

        def failure_message
          "expected #{@object} to protect #{@attribute}) from mass assignment (#{@new_value.inspect} replaced #{@old_value.inspect})"
        end

        def negative_failure_message
          "expected #{@object} not to protect #{@attribute} from mass assignment (#{@new_value.inspect} did not replace #{@old_value.inspect})"
        end
      end

      # Make sure that a given model prevents the mass assignment of
      # a given attribute.
      #
      # Usage example:
      # 
      #   @post.should prevent_mass_assignment_of(:created_at)
      # 
      def prevent_mass_assignment_of(attribute)
        PreventMassAssignmentOf.new(attribute)
      end

      class SendEmails #:nodoc:
        def initialize(count)
          @count = count
        end
  
        def matches?(target)
          @target = target
    
          # exeute change
          ActionMailer::Base.deliveries = []
          @target.call
          case @count
          when Symbol:  !ActionMailer::Base.deliveries.empty?
          when Integer: ActionMailer::Base.deliveries.size == @count
          when Range:   @count.include?(ActionMailer::Base.deliveries.size)
          else
            raise ArgumentError, 'Can only compare number of e-mails with :any, an integer or a range'
          end
        end

        def failure_message
          "expected block to trigger the sending of #{@count} e-mails."
        end

        def negative_failure_message
          "expected block not to trigger the sending of #{@count} e-mails."
        end
      end

      # Make sure that a block of code triggers the sending of one
      # or more e-mails.
      #
      # Usage example:
      #
      #   # test for any number of e-mails
      #   lambda { @user.notify_via_email }.should send_email
      #
      #   # test for one e-mail
      #   lambda { @user.send_activation_code }.should send_an_email
      #
      #   # test for any fixed number of e-mails
      #   lambda { User.spam_everybody }.should send_emails(100)
      #
      #   # test if the number of e-mails is between two values
      #   lambda { User.spam_moderators }.should send_emails(5..25)
      # 
      # Also see <tt>#send_an_email</tt> and <tt>#send_emails</tt>.
      def send_email
        SendEmails.new(:any)
      end

      # Matcher to test if a code block sends one e-mail. See
      # <tt>#send_email</tt> for more details.
      def send_an_email
        SendEmails.new(1)
      end

      # Matcher to test if a code block sends a given amount of e-mails
      def send_emails(number_of_emails)
        SendEmails(number_of_emails)
      end

      class YieldWith #:nodoc:
        def initialize(method)
          @method = method
          @arguments = nil
        end

        def with(*arguments)
          @arguments = arguments
          self
        end

        # This matcher works by setting a dummy variable and changing
        # that variable inside of a block. If the variable changes,
        # the block must have been called.
        def matches?(object)
          @object = object
    
          raise ArgumentError, 'expected the method to exist' unless @object.respond_to?(@method)
    
          x = 1
          if @arguments.nil?
            @object.send(@method) { x = 2 }
          else
            @object.send(@method, *@arguments) { x = 2 }
          end
          return x == 2
        end
  
        def failure_message
          "Expected #{@object}.#{@method} to execute the given block"
        end
  
        def negative_failure_message
          "Expected #{@object}.#{@method} to ignore the given block"
        end
      end

      # This matcher checks if calling a certain method on an object
      # makes it yield to a passed in block.
      #
      # Usage example:
      #
      #   # in your User model
      #   def only_admin
      #     yield if admin? 
      #   end
      #   
      #   # in your test
      #   @user.should_receive(:admin?).and_return(true)
      #   @user.should yield_with(:only_admin)
      # 
      def yield_with(method)
        YieldWith.new(method)
      end
    end
  end
end