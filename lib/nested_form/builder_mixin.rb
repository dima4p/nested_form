module NestedForm
  module BuilderMixin
    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    #   f.link_to_add("Add Task", :tasks)
    #
    # If you want other tag (not <div>) to be used to hold the content of the
    # inserted partial, say, <tr>, use option :enclosing_tag.
    #
    #   f.link_to_add("Add Task", :tasks, :enclosing_tag => 'tr')
    #
    # You can also pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    #     Add Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop
      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      tag = options[:enclosing_tag].to_s || 'div'
      tags  = case tag.downcase
              when 'dd' then [%w[dl]]
              when 'dt' then [%w[dl]]
              when 'li' then [%w[ul]]
              when 'td' then [%w[table], 'tbody', %w[tr]]
              when 'th' then [%w[table], 'tbody', %w[tr]]
              when 'tr' then [%w[table], %w[tbody]]
              else [%w[div]]
              end
      tags.first.push :hide
      tags.last.push :id
      @fields ||= {}
      @template.after_nested_form(association) do
        model_object = object.class.reflect_on_association(association).klass.new
        output = tags.map do |tag, *ops|
          res = "<#{tag}"
          res << %Q[ style="display: none"] if ops.include? :hide
          res << %Q[ id="#{association}_fields_blueprint"] if ops.include? :id
          res << '>'
        end.join.html_safe
        output << fields_for(association, model_object, :child_index => "new_#{association}", :enclosing_tag => tag, &@fields[association])
        output.safe_concat tags.reverse.map{|tag, *ops| "</#{tag}>"}.join
        output
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argment is the name of the link.
    #
    #   f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    #     Remove Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      hidden_field(:_destroy) + @template.link_to(*args, &block)
    end

    def fields_for_with_nested_attributes(association_name, *args)
      # TODO Test this better
      block = args.pop || Proc.new { |fields| @template.render(:partial => "#{association_name.to_s.singularize}_fields", :locals => {:f => fields}) }
      @fields ||= {}
      @fields[association_name] = block
      super(association_name, *(args << block))
    end

    def fields_for_nested_model(name, object, options, block)
      tag = options[:enclosing_tag].to_s || 'div'
      output = %Q[<#{tag} class="fields">].html_safe
      output << super
      output.safe_concat(%Q(</#{tag}>))
      output
    end
  end
end
