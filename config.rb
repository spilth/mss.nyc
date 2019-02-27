  require 'pdf_generator'

page '/*.json', layout: false
page 'songs/*', layout: 'song'

activate :autoprefixer do |prefix|
  prefix.browsers = 'last 2 versions'
end

activate :directory_indexes

activate :s3_sync do |s3_sync|
  s3_sync.bucket = 'mss.nyc'
  s3_sync.acl    = 'public-read'
end

Dir.glob('source/songs/*.html.sng').each do |filename|
  contents = File.read(filename)
  song = SongPro.parse(contents)
  proxy "/songs/#{song.title.parameterize}.html", '/songs/template.html', locals: { song: song}, ignore: true
end

activate :pdf_generator

set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true, smartypants: true

activate :external_pipeline,
         name: :webpack,
         command: build? ?
                      'NODE_ENV=production ./node_modules/webpack/bin/webpack.js --bail -p' :
                      './node_modules/webpack/bin/webpack.js --watch -d --progress --color',
         source: 'tmp/dist',
         latency: 1

helpers do
  def pdf_songs
    Dir.glob('source/songs/*.html.sng').sort.collect do |filename|
      song = SongPro.parse(File.read(filename))
      {
          title: song.title,
          artist: song.artist,
          difficulty: song.custom[:difficulty],
          path: song.title.parameterize,
          short: song.custom[:short],
          ignore: song.custom[:ignore],
      }
    end.reject! do |song|
      song[:ignore]
    end
  end

  def difficulty_text(difficulty)
    case difficulty
    when '1'
      'Easy'
    when '2'
      'Medium'
    end
  end
end
