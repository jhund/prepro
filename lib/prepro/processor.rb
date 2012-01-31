# Abstract class with common features for Processors. Use this for any objects that will receive
# attributes and will cause a persisted record to be changed or updated. In other words:
# Use it for the create, update, and destroy actions in a rails app.
module Prepro
  class Processor
  
    # Creates a new model_instance based on model_attrs.
    # @param[Hash] model_attrs The attributes for the new model_instance. Includes DB columns,
    #     associated objects, nested attributes, etc.
    # @param[User, AnonymousUser, Nil] actor The actor who creates the model_instance
    # @return[Array<ModelInstance, Boolean>] A tuple with the newly created model_instance and a
    #     success flag.
    def self.create(model_attrs, actor, options = {})
      processor_attrs = OpenStruct.new(:attributes => model_attrs, :actor => actor, :options => options)
      model_instance = model_class.new
      enforce_permissions(model_instance.creatable_by?(actor))
      before_assign_attributes_on_create(model_instance, processor_attrs)
      model_instance.assign_attributes(model_attrs, :as => options[:as])
      before_save_on_create(model_instance, processor_attrs)
      success = model_instance.save
      [model_instance, success]
    end
  
    # Updates an existing model_instance based on model_attrs.
    # @param[Hash] model_attrs The attributes for the updated model_instance. Includes DB columns,
    #     the model's id, associated objects, nested attributes, etc.
    # @param[User, AnonymousUser, Nil] actor The actor who updates the model_instance
    # @return[Array<ModelInstance, Boolean>] A tuple with the updated model_instance and a success flag.
    def self.update(model_attrs, actor, options = {})
      processor_attrs = OpenStruct.new(:attributes => model_attrs, :actor => actor, :options => options)
      model_instance = model_class.find(model_attrs[:id])
      enforce_permissions(model_instance.updatable_by?(actor))
      before_assign_attributes_on_update(model_instance, processor_attrs)
      model_instance.assign_attributes(model_attrs, :as => options[:as])
      before_save_on_update(model_instance, processor_attrs)
      success = model_instance.save
      [model_instance, success]
    end
  
    # Destroys an existing model_instance based on model_id
    # @param[Integer, String<Number>] model_id The id of the model_instance to be destroyed
    # @param[User, AnonymousUser, Nil] actor The actor who updates the model_instance
    # @return[Array<ModelInstance, Boolean>] A tuple with the destroyed model_instance and a success flag.
    def self.destroy(model_id, actor, options = {})
      model_instance = model_class.find(model_id)
      enforce_permissions(model_instance.destroyable_by?(actor))
      model_instance.destroy
      [model_instance, true]
    end

    # Alias the basic access methods, so that they can be called for classes further down the
    # inheritance chain, after another class overrode the method
    # Aliasing class methods can only be done in the singleton method
    # See: http://athikunte.blogspot.com/2008/03/aliasmethod-for-class-methods.html
    class << self
      alias_method :create_original, :create
      alias_method :update_original, :update
    end

  private

    def self.before_assign_attributes_on_create(model_instance, processor_attrs)
    end

    def self.before_save_on_create(model_instance, processor_attrs)
    end

    def self.before_assign_attributes_on_update(model_instance, processor_attrs)
    end

    def self.before_save_on_update(model_instance, processor_attrs)
    end

    def self.model_class
      raise "Implement me in concrete processor"
    end
  
    # Raises an AuthorizationError if actor doesn't have permission
    # @param[Boolean] has_permission indicates whether actor has permission
    # @return[Nil] nil, or raises AuthorizationError
    def self.enforce_permissions(has_permission)
      raise Prepro::AuthorizationError  unless has_permission
    end
  
    def self.make_processable(model_instance, processor_attrs)
      # nothing to do here, override in specific processors
    end
  
  end
end
