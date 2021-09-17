require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    class UpdateDmgHelper
      attr_accessor :verbose, :source, :output_filename

      def initialize(params: nil)
        self.params = params
        self.verbose = self.params[:verbose] == true
        self.source = File.expand_path(self.params[:source])
        source_basename_no_extension = File.basename(self.source, File.extname(source))
        output_filename = self.params[:output_filename] || "#{File.dirname(self.source)}/#{source_basename_no_extension}.dmg"
        self.output_filename = File.expand_path(output_filename)
      end

      def update_dmg_parameters
        parameters = {
          '--source'       => self.source,
          '--output-dmg'   => self.output_filename,
          '--template-dmg' => self.params[:template]
        }

        update_dmg_parameters = []
        parameters.each do |key, value|
          if value
            update_dmg_parameters << key.to_s
            update_dmg_parameters << value.to_s
          end
        end

        update_dmg_parameters << '--hdiutil-verbose' if self.params[:hdiutil_verbose]
        update_dmg_parameters << '--hdiutil-quiet'   if self.params[:hdiutil_quiet]

        return update_dmg_parameters
      end

      private

      attr_accessor :params
    end
  end
end
