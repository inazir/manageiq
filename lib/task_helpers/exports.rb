module TaskHelpers
  class Exports
    def self.get_tmp_filename(my_object)
      # Description: This method is used to generate a legacy, error-prone filename based on selected string fields.
      # There is no handling of CustomButtons because safe_filename is not called.
      # Build Arrays for plain classes where filenames are either set by name or description
      description_types = [MiqAlert, MiqAlertSet, MiqPolicy, MiqPolicySet, Classification, MiqWidget]
      names_types = [GenericObjectDefinition, MiqReport, ScanItemSet, MiqSchedule]
      tmp_filename = ''
      if names_types.include?(object.class)
        tmp_filename = object.name
      elsif description_types.include?(object.class)
        tmp_filename = object.description
      # Handle specifically crafted Hashes
      elsif object.class == Hash
        # CustomizationTemplate Hash
        if object[:class].include?("CustomizationTemplate")
          image_type_name = object.fetch_path(:pxe_image_type, :name) || "Examples"
          tmp_filename = "#{image_type_name}-#{object[:name]}"
          # Provisioning Dialog Hash
        elsif object[:class].include?("MiqDialog")
          tmp_filename = "#{object[:dialog_type]}-#{object[:name]}"
          # Role Hash
        elsif object[:class].include?("MiqUserRole")
          tmp_filename = role_hash[:name]
          # Service Dialog Hash
        elsif object[:class].include?("Dialog")
          tmp_filename = object[:label]
        end
      end
      tmp_filename
    end

    def self.safe_filename(object, keep_spaces = false, super_safe_filename = false)
      # Description: generate a safe filename either by some string fields or by object id's.
      # We expect parameter object to be a crafted hash or a miq class suitable for export.

      new_filename = ''
      # Generate filename by id. Hashes and Miq classes must be handled.
      if super_safe_filename
        new_filename = object.class == Hash ? object[:id] : object.id
      # Generate filename by not so safe strings.
      else
        tmp_filename = Exports.get_tmp_filename(object)
        new_filename = keep_spaces ? tmp_filename : tmp_filename.gsub(%r{[ ]}, '_')
        new_filename.gsub(%r{[|/]}, '/' => 'slash', '|' => 'pipe')
      end
      new_filename
    end

    def self.parse_options
      require 'optimist'
      options = Optimist.options(EvmRakeHelper.extract_command_options) do
        opt :keep_spaces, 'Keep spaces in filenames', :type => :boolean, :short => 's', :default => false
        opt :directory, 'Directory to place exported files in', :type => :string, :required => true
        opt :all, 'Export read-only objects', :type => :boolean, :default => false
        opt :super_safe_filename, 'Filenames are generated by object id', :type => :boolean, :default => true
      end

      error = validate_directory(options[:directory])
      Optimist.die :directory, error if error

      options
    end

    def self.validate_directory(directory)
      unless File.directory?(directory)
        return 'Destination directory must exist'
      end

      unless File.writable?(directory)
        return 'Destination directory must be writable'
      end

      nil
    end

    def self.exclude_attributes(attributes, excluded_attributes)
      attributes.reject { |key, _| excluded_attributes.include?(key) }
    end
  end
end
