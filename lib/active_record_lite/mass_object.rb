class MassObject
  def self.my_attr_accessible(*attributes)
    @attributes = attributes

    @attributes.each do |arg|

      define_method("#{arg}=") do |val|
        instance_variable_set("@#{arg}", val)
      end

      define_method(arg) do
        instance_variable_get("@#{arg}")
      end
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, attr_val|
      if self.class.attributes.include?(attr_name.to_sym)
        send("#{attr_name.to_s}=", attr_val)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end