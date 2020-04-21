# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe Source, type: :model do
  let(:terra) { Terraform }
  let(:instance_terra) { instance_double(Terraform) }

  before do
    allow(terra).to receive(:new).and_return(instance_terra)
    allow(instance_terra).to receive(:validate)
  end

  it 'has unique filenames' do
    static_filename = 'static'
    create(:source, filename: static_filename)
    expect do
      create(:source, filename: static_filename)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'when importing' do
    let(:source_dir) { Faker::File.dir(root: '/') }
    let(:subdir) { Faker::File.dir(segment_count: 1) }
    let(:filename) { Faker::File.file_name(dir: nil) }
    let(:relative_path) { File.join(subdir, filename) }
    let(:short_path) { File.join(source_dir, filename) }
    let(:long_path) { File.join(source_dir, subdir, filename) }
    let(:content) { Faker::Lorem.paragraph }

    before do
      allow_any_instance_of(described_class)
        .to receive(:terraform_validation).and_return(true)
    end

    it 'stores the filename without any path if no additional path specified' do
      allow(File).to receive(:read).with(short_path).and_return(content)

      source = described_class.import(source_dir, filename)

      expect(source.filename).not_to include(source_dir)
      expect(source.content).to eq(content)
    end

    it 'stores relative path in filename' do
      allow(File).to receive(:read).with(long_path).and_return(content)

      source = described_class.import(source_dir, relative_path)

      expect(source.filename).not_to include(source_dir)
      expect(source.filename).to eq(relative_path)
      expect(source.content).to eq(content)
    end
  end

  context 'when exporting' do
    let(:source) { create(:source) }
    let(:random_path) do
      Rails.root.join('tmp', Faker::File.dir(segment_count: 1))
    end

    before do
      Rails.configuration.x.source_export_dir = random_path
      FileUtils.mkdir_p(random_path)
    end

    after do
      FileUtils.rm_rf(random_path)
    end

    it 'writes to a file' do
      source.export_into(random_path)
      expected_export_path = File.join(random_path, source.filename)
      expect(File).to exist(expected_export_path)
      file_content = File.read(expected_export_path)
      expect(file_content).to eq(source.content)
    end

    it 'writes to the config path unless otherwise specified' do
      source.export
      expected_export_path = File.join(
        Rails.configuration.x.source_export_dir, source.filename
      )
      expect(File).to exist(expected_export_path)
    end
  end
end
