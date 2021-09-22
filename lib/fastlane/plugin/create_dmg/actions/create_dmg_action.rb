require 'fastlane/action'
require 'fastlane/boolean'
require 'fastlane_core/configuration/config_item'

require_relative '../helper/create_dmg_helper'

module Fastlane
  module Actions
    module SharedValues
      CREATE_DMG_OUTPUT_PATH = :CREATE_DMG_OUTPUT_PATH
    end

    class CreateDmgAction < Action
      UI = FastlaneCore::UI

      def self.run(params)
        helper = Fastlane::Helper::CreateDmgHelper.new(params: params)

        if File.exist?(helper.output_filename)
          UI.message("Remove #{helper.output_filename}") if helper.verbose
          File.delete(helper.output_filename)
        end

        temp_source_folder = Dir.mktmpdir('create-dmg')

        create_dmg_parameters = helper.create_dmg_parameters

        create_dmg_script_path = File.expand_path("#{__dir__}/../vendor/create-dmg/create-dmg")

        create_dmg_parameters.insert(0, create_dmg_script_path)
        create_dmg_parameters << temp_source_folder

        begin
          UI.message("Copy source '#{helper.source}' to temp folder '#{temp_source_folder}'") if helper.verbose
          Actions.sh(
            'ditto', '--rsrc', '--extattr', helper.source, "#{temp_source_folder}/#{helper.source_basename}",
            log: helper.verbose
          )
          UI.message("Create DMG at #{helper.output_filename}") if helper.verbose
          Actions.sh(
            create_dmg_parameters,
            log: true
          )
        ensure
          UI.message("Delete temp folder #{temp_source_folder}") if helper.verbose
          FileUtils.rm_rf(temp_source_folder)
        end

        UI.success("Successfully created DMG")
        UI.message(helper.output_filename)

        Actions.lane_context[SharedValues::CREATE_DMG_OUTPUT_PATH] = helper.output_filename
        ENV[SharedValues::CREATE_DMG_OUTPUT_PATH.to_s] = helper.output_filename

        return helper.output_filename
      end

      def self.description
        "A Ruby wrapper over create-dmg."
      end

      def self.authors
        ["Vitalii Budnik"]
      end

      def self.output
        [
          ['CREATE_DMG_OUTPUT_PATH', 'The path to the created DMG']
        ]
      end

      def self.return_value
        'The path to the created DMG'
      end

      def self.return_type
        :string
      end

      def self.details
        # Optional:
        "A Ruby wrapper over create-dmg - A shell script to build fancy DMGs."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :source,
                                  env_name: "CREATE_DMG_SOURCE",
                               description: "Path to the folder or file to be archived to dmg",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Could not find folder at #{value}") unless File.exist?(value)
                                            end),
          FastlaneCore::ConfigItem.new(key: :output_filename,
                                  env_name: "CREATE_DMG_OUTPUT_FILENAME",
                               description: "Path to the folder to be archived to dmg",
                                  optional: true,
                                      type: String),

          # Volume options
          FastlaneCore::ConfigItem.new(key: :volume_name,
                                  env_name: "CREATE_DMG_VOLUME_NAME",
                               description: "Volume name displayed in the Finder sidebar and window title",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :volume_icon,
                                  env_name: "CREATE_DMG_VOLUME_ICON",
                               description: "Volume icon (*.incs)",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :volume_format,
                                  env_name: "CREATE_DMG_VOLUME_FORMAT",
                               description: "The final image format. 'UDZO' or 'UDBZ'",
                                  optional: true,
                                      type: String,
                             default_value: 'UDZO',
                              verify_block: proc do |value|
                                              UI.user_error!("Could not find folder at '#{value}'") unless ['UDZO', 'UDBZ'].include?(value)
                                            end),
          FastlaneCore::ConfigItem.new(key: :volume_size,
                                  env_name: "CREATE_DMG_VOLUME_SIZE",
                               description: "Disk image size (in MB)",
                                  optional: true,
                                      type: Integer),

          # Window options
          FastlaneCore::ConfigItem.new(key: :window_position,
                                  env_name: "CREATE_DMG_WINDOW_POSITION",
                               description: "Position of the disk image window on the screen X Y coordinates. E.g. '420 150'",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :window_size,
                                  env_name: "CREATE_DMG_WINDOW_SIZE",
                               description: "Size of the disk image window on the screen WIDTH HEIGHT. E.g. '480 320'",
                                  optional: true,
                                      type: String),

          # Disk image folder options
          FastlaneCore::ConfigItem.new(key: :background,
                                  env_name: "CREATE_DMG_BACKGROUND",
                               description: "Disk Image folder background image (png, gif, jpg)",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :icon_size,
                                  env_name: "CREATE_DMG_ICON_SIZE",
                               description: "Icon size inside the DMG folder. Up to 128",
                                  optional: true,
                                      type: Integer),
          FastlaneCore::ConfigItem.new(key: :text_size,
                                  env_name: "CREATE_DMG_TEXT_SIZE",
                               description: "Text size inside the DMG folder (10-16)",
                                  optional: true,
                                      type: Integer),
          FastlaneCore::ConfigItem.new(key: :source_icon_position,
                                  env_name: "CREATE_DMG_SOURCE_ICON_POSITION",
                               description: "Position of the file's icon 'X Y'. E.g. '10 10'",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :hide_source_extension,
                                  env_name: "CREATE_DMG_HIDE_SOURCE_EXTENSION",
                               description: "Hide the source extension",
                                  optional: true,
                                      type: Boolean),

          # Link positions
          FastlaneCore::ConfigItem.new(key: :applications_folder_position,
                                  env_name: "CREATE_DMG_APPLICATIONS_FOLDER_ICON_POSITION",
                               description: "Position of the /Applications folder icon 'X Y'. E.g. '150 10'",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :quick_look_folder_position,
                                  env_name: "CREATE_DMG_SOURCE_ICON_POSITION",
                               description: "Position of the QuickLook install folder icon 'X Y'. E.g. '150 150'",
                                  optional: true,
                                      type: String),

          # EULA
          FastlaneCore::ConfigItem.new(key: :eula_filename,
                                  env_name: "CREATE_DMG_EULA_FILENAME",
                               description: "A path to the end-user license agreement file",
                                  optional: true,
                                      type: String),

          # Additional files
          FastlaneCore::ConfigItem.new(key: :addiional_files,
                                  env_name: "CREATE_DMG_ADDITIONAL_FILES",
                               description: "A list of files to add '<target_name> <file>|<folder> <x> <y>'. E.g. 'Another.app Second.app 200 200'",
                                  optional: true,
                                      type: Array),

          # hdiutil
          FastlaneCore::ConfigItem.new(key: :hdiutil_verbose,
                                  env_name: "CREATE_DMG_HDUTIL_VERBOSE",
                               description: "Execute hdiutil in verbose mode",
                       conflicting_options: [:hdiutil_quiet],
                                  optional: true,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :hdiutil_quiet,
                                  env_name: "CREATE_DMG_HDUTIL_QUIET",
                               description: "Execute hdiutil in quiet mode",
                       conflicting_options: [:hdiutil_verbose],
                                  optional: true,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :hdiutil_sandbox_safe,
                                  env_name: "CREATE_DMG_HDUTIL_SANDBOX_SAFE",
                               description: "Execute hdiutil with sandbox compatibility and do not bless. Some options are unavailable if this options is set to true",
                                  optional: true,
                                      type: Boolean,
                             default_value: false),

          # Plugin options
          FastlaneCore::ConfigItem.new(key: :verbose,
                                  env_name: "CREATE_DMG_VERBOSE",
                               description: "Whether to log create-dmg output",
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
