class MassObject
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
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

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
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