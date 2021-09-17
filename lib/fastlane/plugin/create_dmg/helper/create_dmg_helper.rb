require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    class CreateDmgHelper
      attr_accessor :verbose, :source, :source_basename, :output_filename

      def initialize(params: nil)
        self.params = params
        self.verbose = self.params[:verbose] == true
        self.source = File.expand_path(self.params[:source])
        self.source_basename = File.basename(self.source)
        self.source_basename_no_extension = File.basename(self.source, File.extname(self.source))
        output_filename = self.params[:output_filename] || "#{File.dirname(self.source)}/#{self.source_basename_no_extension}.dmg"
        self.output_filename = File.expand_path(output_filename)
      end

      # rubocop:disable Metrics/PerceivedComplexity
      def create_dmg_parameters
        volume_name = self.params[:volume_name] || self.source_basename_no_extension
        addiional_files = self.params[:addiional_files] || []

        self.verbose = self.params[:verbose] == true

        if params[:hdiutil_sandbox_safe]
          ## TODO: Warnings about turned off but used options
        end

        parameters = {
          '--volname'         => volume_name,
          '--volicon'         => self.params[:volume_icon],
          '--format'          => self.params[:volume_format],
          '--disk-image-size' => self.params[:volume_size],

          '--window-pos'      => self.params[:window_position],
          '--window_size'     => self.params[:window_size],

          '--background'      => self.params[:background],
          '--text-size'       => self.params[:text_size],
          '--icon-size'       => self.params[:icon_size],

          '--app-drop-link'   => self.params[:applications_folder_position],
          '--ql-drop-link'    => self.params[:quick_look_folder_position],

          '--eula'            => self.params[:eula_filename]
        }

        if self.params[:source_icon_position]
          parameters['--icon'] = "#{self.source_basename} #{self.params[:source_icon_position]}"
        end

        if self.params[:hide_source_extension]
          parameters['--hide-extension'] = self.source_basename
        end

        create_dmg_parameters = []
        parameters.each do |key, value|
          if value
            create_dmg_parameters << key.to_s
            create_dmg_parameters << value.to_s
          end
        end

        addiional_files.each do |additional_file|
          create_dmg_parameters << '--file'
          create_dmg_parameters << additional_file
        end

        create_dmg_parameters << '--hdiutil-verbose'     if self.params[:hdiutil_verbose]
        create_dmg_parameters << '--hdiutil-quiet'       if self.params[:hdiutil_quiet]
        create_dmg_parameters << '--sandbox-safe'        if self.params[:hdiutil_sandbox_safe]

        create_dmg_parameters << '--no-internet-enable' # `internet-enable` is not supported any more.

        create_dmg_parameters << self.output_filename

        return create_dmg_parameters
      end
      # rubocop:enable Metrics/PerceivedComplexity

      private

      attr_accessor :params, :source_basename_no_extension
    end
  end
end
