require 'fastlane_core/configuration/config_item'

describe Fastlane::Actions::CreateDmgAction do
  describe 'create-dmg' do
    context 'params' do
      let(:source) { File.expand_path('fastlane') }
      let(:output_filename) { File.expand_path('output.dmg') }
      let(:verbose) { true }
      let(:volume_name) { 'rnd' }
      let(:volume_icon) { 'icon.icns' }
      let(:window_position) { '100 100' }
      let(:window_size) { '300 300' }
      let(:background) { 'background.gif' }
      let(:text_size) { "24" }
      let(:icon_size) { "127" }
      let(:applications_folder_position) { '5 5' }
      let(:quick_look_folder_position) { '15 15' }
      let(:eula_filename) { 'eula.mit.txt' }
      let(:source_icon_position) { '20 20' }
      let(:hide_source_extension) { true }
      let(:hdiutil_verbose) { true }

      it 'executes create-dmg with correct params' do
        expect(Fastlane::Actions).to receive(:sh)
          .with(
            'ditto', '--rsrc', '--extattr', source, anything,
            { log: verbose }
          )
        expect(Fastlane::Actions).to receive(:sh)
          .with(
            [
              File.expand_path("#{__dir__}/../lib/fastlane/plugin/create_dmg/vendor/create-dmg/create-dmg"),
              "--volname",
              volume_name,
              "--volicon",
              volume_icon,
              "--format",
              "UDZO",
              "--window-pos",
              window_position,
              "--window_size",
              window_size,
              "--background",
              background,
              "--text-size",
              text_size,
              "--icon-size",
              icon_size,
              "--app-drop-link",
              applications_folder_position,
              "--ql-drop-link",
              quick_look_folder_position,
              "--eula",
              eula_filename,
              "--icon",
              "#{File.basename(source)} 20 20",
              "--hide-extension",
              File.basename(source),
              "--hdiutil-verbose",
              "--no-internet-enable",
              output_filename,
              anything
            ],
            { log: verbose }
          )
        # .and_return('success_submit_response')

        result = Fastlane::FastFile.new.parse("lane :test do
          create_dmg(
            source: '#{source}',
            output_filename: '#{output_filename}',
            verbose: '#{verbose}',
            volume_name: '#{volume_name}',
            volume_icon: '#{volume_icon}',
            window_position: '#{window_position}',
            window_size: '#{window_size}',
            background: '#{background}',
            text_size: '#{text_size}',
            icon_size: '#{icon_size}',
            applications_folder_position: '#{applications_folder_position}',
            quick_look_folder_position: '#{quick_look_folder_position}',
            eula_filename: '#{eula_filename}',
            source_icon_position: '#{source_icon_position}',
            hide_source_extension: '#{hide_source_extension}',
            hdiutil_verbose: '#{hdiutil_verbose}'
          )
        end").runner.execute(:test)
      end
    end
  end
end
