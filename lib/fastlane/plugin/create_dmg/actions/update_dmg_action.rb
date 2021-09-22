require 'fastlane/action'
require 'fastlane/boolean'
require 'fastlane_core/configuration/config_item'

require_relative '../helper/update_dmg_helper'

module Fastlane
  module Actions
    module SharedValues
      UPDATE_DMG_OUTPUT_PATH = :UPDATE_DMG_OUTPUT_PATH
    end

    class UpdateDmgAction < Action
      UI = FastlaneCore::UI

      def self.run(params)
        helper = Fastlane::Helper::UpdateDmgHelper.new(params: params)

        update_dmg_parameters = helper.update_dmg_parameters

        update_dmg_script_path = File.expand_path("#{__dir__}/../assets/update-dmg.sh")

        update_dmg_parameters.insert(0, update_dmg_script_path)
        UI.message("Create DMG at #{params[:output_filename]}") if helper.verbose
        Actions.sh(
          update_dmg_parameters,
          log: helper.verbose
        )

        UI.success("Successfully created DMG")
        UI.message(helper.output_filename)

        Actions.lane_context[SharedValues::UPDATE_DMG_OUTPUT_PATH] = helper.output_filename
        ENV[SharedValues::UPDATE_DMG_OUTPUT_PATH.to_s] = helper.output_filename

        return helper.output_filename
      end

      def self.description
        "Update files in template DMG"
      end

      def self.authors
        ["Vitalii Budnik"]
      end

      def self.output
        [
          ['UPDATE_DMG_OUTPUT_PATH', 'The path to the updated DMG']
        ]
      end

      def self.return_value
        'The path to the updated DMG'
      end

      def self.return_type
        :string
      end

      def self.details
        # Optional:
        "Update files in template DMG."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :source,
                                  env_name: "UPDATE_DMG_SOURCE",
                               description: "Path to the folder or file to be updated in the original dmg",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Could not find folder at '#{value}'") unless File.exist?(value)
                                            end),
          FastlaneCore::ConfigItem.new(key: :output_filename,
                                  env_name: "UPDATE_DMG_OUTPUT_FILENAME",
                               description: "Path to the resulting dmg file",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :template,
                                  env_name: "UPDATE_DMG_OUTPUT_FILENAME",
                               description: "Path to the template DMG where to update file",
                                  optional: true,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Could not find template DMG at '#{value}'") unless File.exist?(value)
                                            end),

          # hdiutil
          FastlaneCore::ConfigItem.new(key: :hdiutil_verbose,
                                  env_name: "UPDATE_DMG_HDUTIL_VERBOSE",
                               description: "Execute hdiutil in verbose mode",
                       conflicting_options: [:hdiutil_quiet],
                                  optional: true,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :hdiutil_quiet,
                                  env_name: "UPDATE_DMG_HDUTIL_QUIET",
                               description: "Execute hdiutil in quiet mode",
                       conflicting_options: [:hdiutil_verbose],
                                  optional: true,
                                      type: Boolean),

          # Plugin options
          FastlaneCore::ConfigItem.new(key: :verbose,
                                  env_name: "UPDATE_DMG_VERBOSE",
                               description: "Whether to log update-dmg output",
                                  optional: true,
                                      type: Boolean)
        ]
      end

      def self.is_supported?(platform)
        [:mac].include?(platform)
      end
    end
  end
end
