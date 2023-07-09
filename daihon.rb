# encoding: utf-8
require 'json'

# s/*.txtを読み込んで処理する。out/に出力する。
# 実行するフォルダにs/*.txtを配置し、空のフォルダoutを作っておくこと。

#    - daihon.rb
#    - s
#      - 00.txt
#      - 01.txt ...
#    - out（空のフォルダを作っておくこと）
#    - template.docx 台本作業用の文書。これに貼り付けて置換する。


# 台本化設定
actresses=[
  {names: ['キャラ名１'],start_no: 0},
  {names: ['キャラ名２'],start_no: 10000},
  {names: ['キャラ名３','同じキャラの別名'],start_no: 20000},
]

# 全シナリオファイルの読み込み
Dir.chdir 's'
files = Dir.glob('*.txt').sort

scenes = []
files.each do |file|
  lines = []
  File.open(file,encoding: 'CP932:UTF-8') do |f|
    name=nil
    while true do
      line = f.gets
      break if line.nil?
      line.strip!
      next if line==''
      if line.start_with?('【')
        name = line.gsub('【','').gsub('】','')
      else
        lines << {name: name,text: line}
        name = nil
      end
    end
  end
  scenes << {name: file,lines: lines}
end
Dir.chdir '../out'

# 話者リスト作成
puts '話者リスト（この出力を確認すること）'
speakers = {}
scenes.each do |scene|
  scene[:lines].each do |line|
    name = line[:name]
    if name.nil? == false
      if speakers[name]==nil
        speakers[name]={}
      end
      speakers[name][scene[:name]]=true
    end
  end
end

speakers.keys.each do |name|
  puts name + "\n\t" + speakers[name].keys.to_s
end

# 付番
actresses.each do |actress|
  no=actress[:start_no]
  names = actress[:names]
  actress[:scenes]={}
  scenes.each do |scene|
    scene[:lines].each do |line|
      flag = false
      names.each do |name|
        if line[:name] == name
          flag = true
          break
        end
      end
      if flag
        line[:no]=no
        no = no + 1
        actress[:scenes][scene[:name]]=true
      end
    end
  end
end

# スクリプト出力
File.open('script.txt','w',encoding: 'cp932') do |f|
  scenes.each do |scene|
    f.puts("//■■■scene:#{scene[:name]} start■■■")
    scene[:lines].each do |line|
      str = ''
      if line[:name]
        if line[:no].nil?
          str = str + "[#{line[:name]}]"
        else
          str = str + "[#{line[:name]}/#{"%05d" % line[:no]}]"
        end
      end
      str = str + line[:text]
      f.puts(str)
    end
    f.puts("//■■■scene:#{scene[:name]} end■■■")
  end
end

# 台本出力
actresses.each do |actress|
  File.open("#{actress[:names][0]}台本.txt",'w',encoding: 'cp932') do |f|
    scenes.each do |scene|
      if !actress[:scenes].include?(scene[:name])
        next
      end
      f.puts("//■■■scene:#{scene[:name]} start■■■")
      scene[:lines].each do |line|
        str = ''
        header = '$●'
        if line[:name]
          if !line[:no].nil? && (line[:no]/10000).floor == (actress[:start_no]/10000).floor
            header = '$■'
            str = str + "【#{line[:name]}/#{"%05d" % line[:no]}】"
          else
            str = str + "【#{line[:name]}】"
          end
        end
        str = str + line[:text]
        f.puts(header + str)
      end
      f.puts("//■■■scene:#{scene[:name]} end■■■")
    end
  end
end

# 台本テキストをWordドキュメントに流し込み
# [検索する文字列]
# ;$●(*^13)
# [置換後の文字列]
# \1
# 
# で、置換後の文字列に「書式」ボタンからフォントの設定をすることで地の文の書式をいじれます。
# （例えば、9ポイントにするなど）
# すべて置換を実行し、文書全体を処理します。
# 
# [検索する文字列]
# ;$■(*^13)
# [置換後の文字列]
# \1
# 
# で、置換後の文字列に「書式」ボタンからフォントの設定をすることで台詞の書式をいじれます。
# （例えば、14ポイント太字にするなど）
# すべて置換を実行し、文書全体を処理します。

# セリフのみ台本出力
actresses.each do |actress|
  File.open("#{actress[:names][0]}台本(セリフのみ).txt",'w',encoding: 'cp932') do |f|
    scenes.each do |scene|
      scene[:lines].each do |line|
        if line[:name]
          if !line[:no].nil? && (line[:no]/10000).floor == (actress[:start_no]/10000).floor
            f.puts("[#{line[:name]}/#{"%05d" % line[:no]}]#{line[:text]}")
          end
        end
      end
    end
  end
end
