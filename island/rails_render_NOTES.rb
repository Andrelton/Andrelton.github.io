

def setup(context, options, block)
  @view   = context
  @options = options
  @block   = block

  @locals  = options[:locals] || {}
  @details = extract_details(options)

  prepend_formats(options[:formats])

  partial = options[:partial]

  if String === partial
    @has_object = options.key?(:object)
    @object     = options[:object]
    @collection = collection_from_options
    @path       = partial
  else
    @has_object = true
    @object = partial
    @collection = collection_from_object || collection_from_options

    if @collection
      paths = @collection_data = @collection.map { |o| partial_path(o) }
      @path = paths.uniq.one? ? paths.first : nil
    else
      @path = partial_path
    end
  end

  if as = options[:as]
    raise_invalid_option_as(as) unless as.to_s =~ /\A[a-z_]\w*\z/
    as = as.to_sym
  end

  if @path
    @variable, @variable_counter, @variable_iteration = retrieve_variable(@path, as)
    @template_keys = retrieve_template_keys
  else
    paths.map! { |path| retrieve_variable(path, as).unshift(path) }
  end

  self
end


def render(context, options, block)
  setup(context, options, block)
  identifier = (@template = find_partial) ? @template.identifier : @path

  @lookup_context.rendered_format ||= begin
    if @template && @template.formats.present?
      @template.formats.first
    else
      formats.first
    end
  end

  if @collection
    instrument(:collection, :identifier => identifier || "collection", :count => @collection.size) do
      render_collection
    end
  else
    instrument(:partial, :identifier => identifier) do
      render_partial
    end
  end
end


def collection_from_options
  if @options.key?(:collection)
    collection = @options[:collection]
    collection.respond_to?(:to_ary) ? collection.to_ary : []
  end
end