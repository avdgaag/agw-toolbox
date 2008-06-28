module AGW
  module Toolbox
    module PlaceholderHelper

      # Create a placeholder message that can be used when there
      # are no results to display in a listing or search results set.
      # A simple HTML div element is returned with the given
      # message as contents. The message defaults to 'Er is niets
      # om weer te geven.'
      #
      # Example usage:
      #
      #   placeholder() # => <div class="placeholder">Er is niets om weer te geven</p>
      #   placeholder('Niets') # => <div class="placeholder">Niets</p>
      #   placeholder('Niets', :span) # => <span class="placeholder">Niets</span>
      #
      def placeholder(label = 'Er is niets om weer te geven.', options = {})
        label ||= 'Er is niets om weer te geven.'
        options.reverse_merge! :tag => 'div', :class => 'placeholder'
        content_tag(options.delete(:tag), label, options)
      end
      alias_method :ph, :placeholder

      # This is a micro placeholder function, used to quickly output
      # either a value or a default message.
      #
      # Example usage:
      # 
      #   <%= phf(@post.title) %> # => <span class="placeholder">Niet opgegeven</span
      #
      def placeholder_for(string, label = 'Niet opgegeven', options = { :tag => :span} )
        string.blank? ? placeholder(label, options) : h(string)
      end
      alias_method :phf, :placeholder_for

      # When given a statement that evaluates to true or false, this method
      # will either print the given block to the page (on true) or return
      # a placeholder using the <tt>#placeholder</tt> method. After the condition
      # the same options can be passed to this method as to <tt>#placeholder</tt>.
      #
      # Example usage:
      #
      #   <% placeholder_unless(@posts.any?, 'there are no posts') do %>
      #     <%= render :partial => @posts %>
      #   <% end %>
      #
      # When <tt>@posts.any?</tt> evaluates to false, this will result in:
      #
      #   <p class="placeholder">there are no posts</p>
      #
      # Otherwise, it will evaluate the code block and render the partial.
      def placeholder_unless(condition, *args, &block)
        return condition ? concat(capture(&block), block.binding) : concat(placeholder(*args), block.binding)
      end
      alias_method :phu, :placeholder_unless
  
      # TODO: document this method
      # TODO: test this method
      def placeholder_with_blank_slate_unless(condition, name, &block)
        return condition ? concat(capture(&block), block.binding) : concat(image_tag("blank-slate-#{name}.png", :alt => "Voorbeeld van #{name}"), block.binding)
      end
      alias_method :pbs, :placeholder_with_blank_slate_unless

      # This method helps simplify the following pattern:
      #
      # * See if there are any objects
      # * If not, print a placeholder
      # * If so, loop the objects
      # * print each object
      #
      # This method eiter prints a placeholder message or renders the
      # given block for each element in the given collection.
      #
      # Usage example:
      #
      #   <% placeholder_or_list(@posts) do |post| -%>
      #     <li><%= post.title %></li>
      #   <% end -%>
      #
      # Result:
      #
      #   <ol>
      #     <li>Post title</li>
      #   </ol>
      #
      # Alternatively, you may omit the block altogether. It will then
      # be attempted to render a partial on the collection.
      #
      # Example:
      #
      #   <%= placeholder_or_list(@posts) %>
      #
      # Is equivalent to:
      #
      #   <% placeholder_or_list(@posts) do |post| -%>
      #     <%= render => post %>
      #   <% end -%>
      #
      # So, this will either call +placeholder+ (when tere are no posts)
      # or render the post partial for every post. Also, it wraps the
      # output in an HTML tag--by default OL. HTML options for this list
      # can be set with a Hash as follows:
      #
      #   <%= placeholder_or_list(@posts, :html_attributes => { :id => 'posts' }) %>
      #
      # The following options are available:
      #
      # * +:list_tag+ for setting the kind of HTML container that should be used. Defaults to +'ol'+.
      # * +:html_attributes+ for setting additional attributes on the list.
      # * +:placeholder+ for setting the placeholder label.
      # * all the options available for +placeholder+.
      def placeholder_or_list(collection, options = {}, &block)
        # set default options
        options.reverse_merge!({
          :list_tag     => 'ol',
          :placeholder  => 'Nothing found.',
          :tag          => 'div'
        })
        
        # Set up HTML
        attributes = options[:html_attributes] ? options[:html_attributes].to_attributes : ''
        start_tag  = "<#{options[:list_tag]}#{attributes}>\n"
        end_tag    = "</#{options[:list_tag]}>\n"
        
        unless collection.blank?
          # Use the block to render HTML if there is one
          # Else try to render a partial
          if block_given?
            concat(start_tag, block.binding)
            concat(collection.inject('') { |output, item| output << capture(item, &block); output }, block.binding)
            concat(end_tag, block.binding)
          else
            output = start_tag
            output << render(:partial => collection)
            output << end_tag
          end
        else
          if block_given?
            concat(placeholder(options[:placeholder], options), block.binding)
          else
            placeholder(options[:placeholder], options)
          end
        end
      end
    end
  end
end    