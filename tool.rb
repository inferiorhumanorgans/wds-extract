#!/usr/bin/env ruby

require 'zip'
require 'nokogiri'
require 'optparse'
require 'set'

class ToolAction
  def self.run(options)
    raise "Not implemented, possibilities are: #{options[:available_actions].keys.sort.join(', ')}"
  end
end

class CopyData < ToolAction
  CMD = "copy-data"

  def self.run(options)
    FileUtils.ln_s(File.join(options[:wds_root], 'release/zi_images'), options[:output_dir])
    FileUtils.ln_s(File.join(options[:wds_root], 'release', options[:wds_language], 'svg'), options[:output_dir])
    FileUtils.ln_s(File.join(options[:wds_root], 'release', options[:wds_language], 'zinfo'), options[:output_dir])
  end
end

class CopyAssets < ToolAction
  CMD = "copy-assets"

  def self.run(options)
    FileUtils.cp_r(File.join(options[:asset_dir], '/.'), options[:output_dir])
  end
end

class ParseModel < ToolAction
  CMD = "generate"

  def self.process_folder(folder, parent, root, suffix)
    STDERR.write '.'
    STDERR.flush

    li = Nokogiri::XML::Node.new('li', parent)
    if folder['id']
      li['name'] = folder['id'].dup
    end

    input = Nokogiri::XML::Node.new('input', li)
    input['id'] = suffix
    input['type'] = 'checkbox'

    label = Nokogiri::XML::Node.new('label', li)
    label['for'] = suffix
    label.content = folder['name'].dup

    li << input
    li << label

    ul = Nokogiri::XML::Node.new('ul', li)
    li << ul

    return if folder.xpath('.//leaf').empty?

    subfolders = folder.xpath('folder')
    leaves = folder.xpath('leaf')

    parent << li

    subfolders.each_with_index do |subfolder, index|
      process_folder(subfolder, ul, root, "#{suffix}-#{index}")
    end

    leaves.each do |leaf|
      link = Nokogiri::XML::Node.new('li', ul)
      a = Nokogiri::XML::Node.new('a', link)

      a.content = leaf['name']
      a['title'] = leaf['name']

      a['target'] = 'duh'

      a['href'] = leaf['link']

      link << a
      ul << link
    end
  end

  def self.run(options)
    options[:target_model].each do |target_model|
      xml_input = nil

      Zip::File.open(File.join(options[:wds_root], 'release', options[:wds_language], target_model, 'tree', 'files.zip')) do |zipfile|
        zipfile.each do |entry|
          xml_input = entry.get_input_stream.read
          break
        end
      end

      output_model_dir = File.join(options[:output_dir], target_model)
      Dir.mkdir(output_model_dir) unless Dir.exists? output_model_dir

      File.open(File.join(options[:template_dir], 'tree.html')) do |html_in|
        xml = Nokogiri::XML(xml_input, &:noblanks)
        html = Nokogiri::HTML(html_in, &:noblanks)

        tree = html.xpath('//div')[0]

        STDERR.write 'Proccessing XML input: '
        STDERR.flush

        xml.xpath('/tree').each{|t|
          t.xpath('root').each{|r|
            r.name='div'
            r.remove_attribute('hidden')
            ul = Nokogiri::XML::Node.new('ul', html)
            tree << ul

            folders = r.xpath('folder')
            folders.each_with_index do |folder, index|
              process_folder(folder, ul, html, "itm-#{index}")
            end
            ul << ('<li><input id="search-0" type="checkbox"><label for="search-0">Search Results</label><ul id="search-results"></ul></li>')
          }
        }

        File.open(File.join(options[:output_dir], target_model, 'index.html'), 'w+') do |html_out|
          gz = Zlib::GzipWriter.new(html_out)
          gz.write html.to_html(indent: 0)
          gz.close
        end

        STDERR.puts ' Done.'
      end
    end
  end
end

class SyncData < ToolAction
  CMD = "upload"

  def self.run(options)
    STDERR.puts "Working on models: #{options[:target_model].to_a.sort.join(", ")}"

    output = `cd work && aws s3 sync . s3://#{options[:s3_bucket]} --sse`
    STDERR.puts output

    options[:target_model].each do |target_model|
      output = `aws s3api copy-object --content-encoding "gzip" --copy-source #{options[:s3_bucket]}/#{target_model}/index.html --key #{target_model}/index.html --metadata-directive REPLACE --bucket #{options[:s3_bucket]} --server-side-encryption AES256 --content-type text/html`
      STDERR.puts output
    end
  end
end


options = {
  cmd:                ARGV[0],
  wds_root:           nil,
  wds_language:       'en',
  output_dir:         File.join(Dir.pwd, 'work'),
  template_dir:       File.join(Dir.pwd, 'templates'),
  asset_dir:          File.join(Dir.pwd, 'assets'),
  target_model:       Set.new,
  available_actions:  ObjectSpace.each_object(::Class).select {|klass| klass < ToolAction}.reduce({}) {|ret, inj| ret[inj.const_get(:CMD)] = inj; ret}
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on('-w', '--wds-root DIRECTORY', 'Directory where your WDS image is mounted') do |arg|
    options[:wds_root] = arg
  end

  opts.on('-m', '--target-model MODEL', 'Model to extract information for') do |arg|
    options[:target_model].add(arg)
  end
  opts.on('-b', '--s3-bucket BUCKET', 'Bucket to store stuff in') do |arg|
    options[:s3_bucket] = arg
  end
end.parse!

action = options[:available_actions][ARGV[0]] || ToolAction

action.run(options)
