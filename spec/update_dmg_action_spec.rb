require 'fastlane_core/configuration/config_item'

describe Fastlane::Actions::UpdateDmgAction do
  describe 'update-dmg' do
    context 'params' do
      let(:source) { File.expand_path('fastlane') }
      let(:output_filename) { File.expand_path('output.dmg') }
      file = Tempfile.new('.dmg')
      file << ""
      file.close
      let(:template) { File.expand_path(file) }
      let(:hdiutil_verbose) { true }
      let(:verbose) { true }

      it 'executes update-dmg with correct params' do
        expect(Fastlane::Actions).to receive(:sh)
          .with(
            [
              File.expand_path("#{__dir__}/../lib/fastlane/plugin/create_dmg/assets/update-dmg.sh"),
              "--source",
              source,
              "--output-dmg",
              output_filename,
              "--template-dmg",
              template,
              "--hdiutil-verbose"
            ],
            { log: verbose }
          )

        result = Fastlane::FastFile.new.parse("lane :test do
          update_dmg(
            source: '#{source}',
            output_filename: '#{output_filename}',
            template: '#{template}',
            hdiutil_verbose: '#{hdiutil_verbose}',
            verbose: '#{verbose}'
          )
        end").runner.execute(:test)
        file.unlink
      end
    end
  end
end
