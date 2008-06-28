module AGW #:nodoc:
  module Toolbox #:nodoc:
    # This module drops in a custom form builder for use
    # with the Ruby on Rails framework. It introduces
    # a new custom form builder and sets is as standard
    # to be used by all calls to <tt>form_for</tt>.
    #
    # It outputs semantically rich and technically correct
    # XHTML Strict code, with baked-in error reporting. It also
    # provides some handy-dandy helper methods to create
    # forms quicker.
    #
    # See <tt>ListedFormBuilder::Builder#create_listed_field</tt> for
    # example output.
    #
    # This file is a drop in replacement. Put this file in
    # your rails project's <tt>lib/</tt> folder and you're good to go.
    #
    # === Colofon
    #
    # *Author*:: Arjan van der Gaag (info@agwebdesign.nl[mailto:info@agwebdesign.nl])
    # *Copyright*:: copyright (c) 2007 {AG Webdesign}[http://agwebdesign.nl]
    # *License*:: distributed under {the same license as Ruby}[http://www.ruby-lang.org/en/LICENSE.txt]
    #
    module ListedFormBuilder
  
      # This is the builder class that inherits from
      # <tt>ActionView::Helpers::FormBuilder</tt>. An instance of this
      # object is yielded by the <tt>form_for</tt> method.
      #
      # Methods for creating individual types of fields are
      # dynamically created. Most field types use
      # <tt>#create_listed_field</tt> to create a method that generates
      # the right HTML. The radio button and checkbox use
      # <tt>#create_option_field</tt>. Finally, the hidden field
      # uses its own explicit method <tt>#hidden_field</tt>. See
      # these functions for details.
      class Builder < ActionView::Helpers::FormBuilder
    
        # Create a complete form row for a given field, together with
        # label, tabindex, HTML structure and any errors.
        #
        # Example usage:
        #
        #   <%= f.text_field :title %>
        #
        # Produces:
        #
        #   <li>
        #     <label for="post_title">Title</label>
        #     <input type="text" id="post_title" name="post[title]" tabindex="1" value="" />
        #   </li>
        #
        # In case of an error on this field, the following output is generated:
        #
        #   <li class="with_error">
        #     <label for="post_title">Title</label>
        #     <input type="text" id="post_title" name="post[title]" tabindex="1" value="" />
        #     <div class="with_error">can't be blank</div>
        #   </li>
        #
        # Note that the <tt>tabindex</tt> property is automatically added to the arguments, which means
        # that the last argument will be changed if it is a Hash. This might not be want you want,
        # for example when you are doing something like this:
        #
        #   <%= f.select :role, { :user => 0, :admin => 1 } %> 
        #   #=> { :tabindex => 1 } will be added to the options Hash
        #
        # In order to keep 'tabindex' out of your list of options, you will have to provide
        # that last optional Hash argument:
        #
        #   <%= f.select :role, { :user => 0, :admin => 1 }, {} %>
        #   #=> { :tabindex => 1 } will be added to the empty Hash.
        #
        def self.create_listed_field(method_name)
          define_method(method_name) do |label, *args|
        
            # get the right label to display next to the field
            human_label = humanize_label(label, *args)

            # Also get any additional information to display next to the field
            description = extract_description(*args)
        
            # Include the right tabindex attribute for the input field
            args = include_next_tabindex(*args)
        
            # collect any errors on this field
            klass, error_description = collect_errors_for(label)

            @template.content_tag('li', 
              @template.content_tag('label', human_label, :for => "#{@object_name}_#{label}" ) + 
              super(label, *args) + 
              error_description + 
              description, 
            :class => klass)
          end
        end
    
        # Create a special version of the form row, aimed at check boxes and radio buttons.
        # It generates a complete row in a form, together with markup and label.
        # Unlike the standard <tt>create_listed_field</tt> though <tt>create_option_field</tt> does
        # not seperate the input field from the label.
        # 
        # Example usage:
        # 
        #   <%= f.check_box :admin %>
        # 
        # Produces:
        # 
        #   <li>
        #     <label><input type="checkbox" name="user[admin]" id="user_admin" value="1" />
        #     Admin</label>
        #   </li>
        # 
        def self.create_option_field(method_name)
          define_method(method_name) do |label, *args|
        
            # get the right label to display next to the field
            human_label = humanize_label(label, *args)
        
            # Also get any additional information to display next to the field
            description = extract_description(*args)
        
            # Include the right tabindex attribute for the input field
            args = include_next_tabindex(*args)
        
            # collect any errors on this field
            klass, error_description = collect_errors_for(label)
        
            # Make sure this list item gets the 'option' class name to distinguish from
            # normal rows in the form.
            klass = ['option', klass].join(' ')
        
            @template.content_tag('li',
              @template.content_tag('label', super(label, *args) + 
              " #{human_label}") +
              error_description +
              description, 
            :class => klass)
          end
        end
    
        # Override the method for hidden fields so that they get
        # wrapped in a DIV-element so it produces XHTML Strict valid code.
        def hidden_field(label, *args)
          @template.content_tag('div', super)
        end
    
        # Provide an easy way to wrap fields in a fieldset with
        # the appropriate list container for the list items.
        # 
        # Example usage:
        # 
        #   <% f.fieldset 'My fieldset' do %>
        #     ...
        #   <% end %>
        # 
        # Produces:
        # 
        #   <fieldset>
        #     <legend>My fieldset</legend>
        #     <ol>
        #     ...
        #     </ol>
        #   </fieldset>
        # 
        # If you need to apply HTML attributes you are better off
        # explicitly writing your own HTML code.
        def fieldset(name, &proc)
          write('<fieldset>', &proc)
          write("  <legend>#{name}</legend>", &proc) unless name.blank?
          list(&proc)
          write('</fieldset>', &proc)
        end
    
        # Provide a way to quickly wrap a list (ol) around
        # a group of fields. This can be used if a form element
        # is not inside of a fieldset (that automatically includes a
        # list element).
        #
        # Note that it is recommended to always use fieldset for
        # reasons of semantics.
        def list(options = {}, &proc)
          write('<ol>', &proc)
          proc.call
          write('</ol>', &proc)
        end
    
        # Output a list item with faux labels and form element. This can be
        # styled using CSS to fit into the form itself, but present a
        # constant, unchangeable value.
        #
        # Example:
        #
        #   f.plain_row('User', 'Andy')
        #
        # Will output:
        #
        #   <li class="plain">
        #     <span class="label">User</span>
        #     <span class="value">Andy</span>
        #   </li>
        # 
        def plain_row(label, value)
          @template.content_tag(:li, 
            @template.content_tag(:span, label, :class => 'label') + 
            @template.content_tag(:span, value, :class => 'value'),
            :class => 'plain')
        end

        # Output a list item with faux labels and form element, but with a
        # hidden form element. This way values appear saved and uneditable,
        # but in a sexier way than using disabled controls.
        #
        # Example:
        #
        #   f.faux_row(:login)
        #
        # Will output:
        #
        #   <li class="plain">
        #     <input type="hidden" name="user[login]" value="Andy" />
        #     <span class="label">Login</span>
        #     <span class="value">Andy</span>
        #   </li>
        #
        def faux_row(attribute, options = {})
          options.reverse_merge! :label => attribute.to_s.humanize
          @template.content_tag(:li, 
            hidden_field(attribute) + 
            @template.content_tag(:span, options[:label], :class => 'label') + 
            @template.content_tag(:span, @object.send(attribute), :class => 'value'),
            :class => 'plain')
        end
    
        # Create a wrapper method to include all buttons in a DIV-element
        # By default, a cancel link is included using #cancel_link. You
        # can override this behaviour by passing in <tt>:with_cancel => false</tt>.
        # Any other options will be passed right to #cancel_link.
        #
        # Example usage:
        #
        #   <% f.button_group do %>
        #     ...
        #   <% end %>
        #
        # Produces the following output:
        #
        #   <div class="button_group">
        #     ...
        #     or <a href="/posts/index" class="cancel">cancel</a>
        #   </div>
        #
        def button_group(cancel_link_options = {}, &proc)
          cancel_link_options.reverse_merge! :with_cancel => true
          write('<div class="button_group">', &proc)
          proc.call
          cancel_link(cancel_link_options, &proc) if cancel_link_options[:with_cancel]
          write('</div>', &proc)
        end
    
        # Creates a link to cancel the operation and return to a previous page.
        # Defaults to "of annuleren", with "annuleren" linking back to the index action.
        #
        # Valid options are:
        # 
        # <tt>:seperator</tt>:: defaults to 'or'
        # <tt>:label</tt>:: defaults to 'cancel'
        # <tt>:class</tt>:: defaults to 'cancel'
        # <tt>:url</tt>:: default to <tt>{ :action => 'index' }</tt>, but can be anything you can pass to <tt>url_for</tt>.
        def cancel_link(options = {}, &proc)
          # Set default options
          options.reverse_merge!  :seperator => 'of', 
                                  :label => 'annuleren', 
                                  :class => 'cancel', 
                                  :url => { :action => 'index' }
      
          # Build the HTML based on the options
          seperator = " #{options.delete(:seperator)} "
          link = @template.link_to(options.delete(:label), options.delete(:url), options )
      
          # Feed the line to the template
          write(seperator + link, &proc)
        end
    
        # Create a button with a label. Pass in extra HTML attributes as a hash.
        # It automatically receives the next applicable tabindex.
        #
        # Example usage:
        #
        #   <%= f.button 'Save' %>
        #
        # Produces:
        #
        #   <button tabindex="1">Save</button>
        #
        # Note that this is a plain button, not a submit button. You could pass in the
        # right HTML attributes as a Hash (just as with <tt>content_tag</tt>) but you should
        # use <tt>#submit</tt> for that.
        def button(name, options = {})
          options.reverse_merge! :tabindex => next_tabindex
          options.reverse_merge! :disabled => 'disabled' if options[:disabled]
          @template.content_tag('button', name, options)
        end
    
        # Shortcut method for #butotn to create a submit button. It is a wrapper method
        # for the <tt>#button</tt> method. The label defaults to _Save_.
        #
        # Example usage:
        #
        #   <%= f.submit %>
        #
        # Produces:
        #
        #   <button type="submit" tabindex="1">Save</button>
        #
        # Just as with <tt>#button</tt> you can pass in extra HTML arguments as a Hash.
        def submit(name = 'Opslaan', options = {})
          options.reverse_merge! :type => 'submit', :title => 'Wijzigingen opslaan'
          button(name, options)
        end
    
        # generate the appropriate methods for generating form fields
        (field_helpers - %w{check_box radio_button hidden_field} + %w{select}).each { |name| create_listed_field(name) }
        %w{check_box radio_button}.each { |name| create_option_field(name) }
    
        private

          # Get any errors on a given attribute for the current object the form builder is
          # working on. Two values are returned: a CSS class name that can be applied
          # to the form row being built, and a container with the error description(s).
          #
          # Usage exaple:
          #
          #   klass, error_description = collect_errors_for(:title)
          #   klass # => 'with_error'
          #   error_desription # => "<div class="with_error">can't be blank</div>"
          def collect_errors_for(label)
            errors = @object.nil? ? nil : @object.errors.on(label)
            case errors
            when nil:   return [nil, '']
            when Array: return formatted_errors(errors.to_sentence(:connector => 'en'))
            else        return formatted_errors(errors)
            end
          end
      
          # Given a string of errors return a container with those errors and a
          # CSS class name to assign to the container element.
          def formatted_errors(errors)
            return ['with_error', @template.content_tag(:div, errors, :class => 'with_error')]
          end

          # Write a line to the template. Shortcut method to output plain text to the template.
          # A line end is appended to the end of the string passed in.
          def write(line, &proc)
            @template.concat("#{line}\n")
          end
  
          # Given an array of arguments for a field function this method
          # will make sure the tabindex option is included. It will be
          # set to <tt>#next_tabindex</tt>.
          #
          # Example usage:
          #
          #   include_next_tabindex(['title', {:class => 'big'}])
          #   #=> ['title', { :class => 'big', :tabindex => 1}]
          #
          def include_next_tabindex(*args)
            options = args.last.is_a?(Hash) ? args.pop : {}
            options = options.merge(:tabindex => next_tabindex)
            args = (args << options)
          end
          @@tabindex = 0
      
          # Given the arguments for a field helper this method will extract
          # a custom attribute in the options hash (if there is any) called
          # <tt>:label</tt> that holds the custom label to use on the row
          # in the database, rather than the humanized column name.
          #
          # If there is no options Hash or no custom label set, the default
          # humanized column name will be returned.
          #
          # Example usage:
          #
          #   def text_field(label, *args)
          #     super(humanize_label(label, *args), *args)
          #   end
          #
          #--
          # TODO: test this method
          #++
          def humanize_label(label, *args)
            human_label = label.to_s.humanize
            if args.last.is_a?(Hash) && custom_label = args.last.delete(:label)
              human_label = custom_label
            end
            return human_label
          end
      
          # Given the arguments for a field helper this method will extract
          # acustom attributei n the options Hash (if there is any) called
          # <tt>:description</tt> that holds any additional information
          # to be displayed in the form row for the input field.
          #
          # If there is no such attribute an empty string will be returned.
          #
          # Example usage:
          #
          #   def text_field(label, *args)
          #     desription = (extract_desciption(*args) || '')
          #     super(label + " (#{description})", *args)
          #   end
          # 
          #--
          # TODO: test this method
          #++
          def extract_description(*args)
            if args.last.is_a?(Hash) && description = args.last.delete(:description)
              return @template.content_tag(:small, description)
            else
              return ''
            end
          end
      
          # Calculate and return the next tabindex.
          # The right number is kept in a class variable and should
          # be consistent across the entire page.
          def next_tabindex
            @@tabindex = @@tabindex + 1
          end

      end
  
      # Provide a shortcut method to a form_for that uses the
      # ListedFormBuilder. This file already sets the
      # listed form builder to the default, but you can manually
      # use this form builder with this method.
      def listed_form_for(name, *args, &proc)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = options.merge(:builder => ListedFormBuilder::Builder)
        args = (args << options)
        form_for(name, *args, &proc)
      end

      # Override the default <tt>error_messages_for</tt> method to
      # only display errors on base. However, a header text
      # is always displayed with the total number of errors.
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        if object = options.delete(:object)
          objects = [object].flatten
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end
        count = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errors'
            end
          end
          options[:object_name] ||= params.first
          options[:header_message] = "Er #{count > 1 ? 'hebben' : 'heeft'} zich #{pluralize(count, 'fout', 'fouten')} voorgedaan." unless options.include?(:header_message)
          if object.errors.on_base
            options[:message] ||= 'De volgende problemen moeten opgelost worden' unless options.include?(:message)
            error_messages = objects.map {|object| object.errors.on_base.map {|msg| content_tag(:li, msg) } }
          end  
          contents = ''
          contents << content_tag(options[:header_tag] || :h3, options[:header_message]) unless options[:header_message].blank?
          contents << content_tag(:p, options[:message]) unless options[:message].blank?
          contents << content_tag(:ul, error_messages) if object.errors.on_base
          content_tag(:div, contents, html)
        else
          ''
        end
      end
      
      # This is where the ListedFormBuilder is set as the default form builder for
      # all calls to <tt>form_for</tt>. You can comment out these lines if you don't want this
      # behaviour. Then you can use <tt>#listed_form_for</tt> instead, or just pass
      # in the <tt>:builder => ListedFormBuilder::Builder</tt> argument to your <tt>form_for</tt>
      # call manually.
      #
      # This also eliminates Rails' default HTML handling of form fields with errors.
      def self.setup
        ActionView::Base.class_eval do
          @@field_error_proc = Proc.new{ |html_tag, instance| html_tag }
          self.default_form_builder = AGW::Toolbox::ListedFormBuilder::Builder
        end
      end
    end
  end
end