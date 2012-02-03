# Abstract class with common features for Presenters. Use this for any objects that will be rendered
# in some shape or form. Use it for read only access, in other words, for index, show, new and edit
# actions in a rails app.
module Prepro
  class Presenter

    # Prepares collection of model instances or a single model instance for presentation
    # @param[Integer, String(number), Hash, Model, Array<Model>] id_model_hash_collection id of model,
    #     attributes for new model, existing model or collection of models to present.
    # @param[User, AnonymousUser] actor the actor who will view the model
    # @param[ActionView::Base] view_context An instance of a view class. The default view class is
    #     ActionView::Base
    # @param[Hash, optional] options:
    #     * :enforce_permissions - default true
    # @return[DecoratedModel, Array<DecoratedModel>] a model or collection thereof, decorated for
    #     presentation
    def self.new(id_model_hash_collection, actor, view_context, options = {})
      options = {
        :enforce_permissions => true
      }.merge(options)
      case id_model_hash_collection
      when Array, ActiveRecord::Relation
        present_collection(id_model_hash_collection, actor, view_context, options)
      else
        present_single(id_model_hash_collection, actor, view_context, options)
      end
    end

    # Alias the basic access methods, so that they can be called for classes further down the
    # inheritance chain, after another class overrode the method
    # Aliasing class methods can only be done in the singleton method
    # See: http://athikunte.blogspot.com/2008/03/aliasmethod-for-class-methods.html
    class << self
      alias_method :new_original, :new
    end

    # Prepares collection of model instances for presentation
    # @param[Array<Model>] model_instances A collection of model instances
    # @param[User, AnonymousUser] actor the actor who will view the model
    # @param[ActionView::Base] view_context An instance of a view class. The default view class is
    #     ActionView::Base
    # @param[Hash, optional] options
    # @return[Array<DecoratedModel>] An array of models, each decorated for presentation
    def self.present_collection(model_instances, actor, view_context, options = {})
      presenter_attrs = OpenStruct.new(
        :actor => actor, :view_context => view_context, :options => options
      )
      if options[:enforce_permissions]
        enforce_permissions(model_class.listable_by?(actor))
      end
      model_instances.each { |e| make_presentable!(e, presenter_attrs) }
      model_instances
    end

    # Prepares a model instance for presentation
    # @param[Integer, String(number), Model] id_hash_model id of model, attributes for model, or model
    #     to present
    # @param[User, AnonymousUser] actor the actor who will view the model
    # @param[ActionView::Base] view_context An instance of a view class. The default view class is
    #     ActionView::Base
    # @param[Hash, optional] options
    # @return[DecoratedModel] a model, decorated for presentation
    def self.present_single(id_hash_model, actor, view_context, options = {})
      presenter_attrs = OpenStruct.new(:actor => actor, :view_context => view_context, :options => options)
      model_instance = load_model_instance(id_hash_model)
      if options[:enforce_permissions]
        enforce_permissions(model_instance.viewable_by?(actor))
      end
      make_presentable!(model_instance, presenter_attrs)
      model_instance
    end

    # Returns a model_instance, based on given id_hash_model
    def self.load_model_instance(id_hash_model)
      case id_hash_model
      when Integer, /\A\d+/
        model_class.find(id_hash_model)
      when Hash
        model_class.new(id_hash_model)
      else
        id_hash_model
      end
    end

    # Override this in your concrete presenters with the class presented by self.
    def self.model_class
      raise "Implement me in concrete presenter"
    end

    # Raises an AuthorizationError if actor doesn't have permission
    # @param[Boolean] has_permission indicates whether actor has permission
    # @return[Nil] nil, or raises AuthorizationError
    def self.enforce_permissions(has_permission)
      raise Prepro::AuthorizationError  unless has_permission
    end

    module DecoratorMixin

      def presenter_attrs=(the_presenter_attrs)
        @presenter_attrs = the_presenter_attrs
      end

      def presenter_attrs
        @presenter_attrs
      end

      # Formats a_datetime
      # @param[DateTime, Nil] a_datetime the datetime to format
      # @param[Symbol] output_format the format to be applied: :distance_in_words,
      #                              or any datetime format specified in initializers
      def formatted_datetime(a_datetime, output_format, options = {})
        return 'N/A'  if a_datetime.blank?
        case output_format
        when :distance_in_words
          if a_datetime < Time.now
            # in the past
            decorated_time_ago_in_words(a_datetime, options)
          else
            # in the future
            decorated_time_from_now_in_words(a_datetime, options)
          end
        else
          a_datetime.to_s(output_format)
        end
      end

      # Renders time ago, showing absolute time on hover
      # @param[DateTime] a_datetime the time to render
      # @param[Hash, optional] options:
      #   * :suffix => printed after the time, default: ' ago'
      #   * :suppress_1 => if the number is a one, suppress it. Used for '... in the last month', which
      #                    reads better than '... in the last 1 month'
      #   * :text_only => skip html tags
      def decorated_time_ago_in_words(a_datetime, options = {})
        options = {
          :suffix => ' ago',
          :suppress_1 => false,
          :text_only => false
        }.merge(options)
        ts = ((presenter_attrs.view_context.time_ago_in_words(a_datetime).gsub('about ', '') + options[:suffix])  rescue 'N/A')
        ts = ts.gsub(/^1\s+/, '')  if options[:suppress_1]
        if options[:text_only]
          ts
        else
          presenter_attrs.view_context.content_tag(:span, ts, :title => a_datetime.to_s(:full_date_and_time))
        end
      end

      # Renders time from now, showing absolute time on hover
      # @param[DateTime] a_datetime the time to render
      # @param[Hash, optional] options:
      #   * :prefix => printed before the time, default: 'in '
      #   * :suppress_1 => if the number is a one, suppress it. Used for '... in the last month', which
      #                    reads better than '... in the last 1 month'
      #   * :text_only => skip html tags
      def decorated_time_from_now_in_words(a_datetime, options = {})
        options = {
          :prefix => 'in ',
          :suppress_1 => false,
          :text_only => false
        }.merge(options)
        ts = (
          (
            options[:prefix] + presenter_attrs.view_context.time_ago_in_words(a_datetime).gsub('about ', '')
          )  rescue 'N/A'
        )
        ts = ts.gsub(/^1\s+/, '')  if options[:suppress_1]
        if options[:text_only]
          ts
        else
          presenter_attrs.view_context.content_tag(:span, ts, :title => a_datetime.to_s(:full_date_and_time))
        end
      end

      def formatted_boolean(a_boolean)
        a_boolean ? 'Yes' : 'No'
      end

      def indicate_blank
        presenter_attrs.view_context.content_tag :span, "None Given", :class => 'label'
      end

    end

  end
end
