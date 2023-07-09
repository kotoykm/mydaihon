# encoding: utf-8
require 'json'

# Leer y procesar archivos s/*.txt. Salida en la carpeta "out/".
# Coloca los archivos s/*.txt en la carpeta de ejecución y asegúrate de crear una carpeta vacía llamada "out".

#    - daihon.rb
#    - s (carpeta)
#      - 00.txt
#      - 01.txt ...
#    - out (Crea una carpeta vacía)

# Configuración para generar el guion

actresses=[
  {names: ["#{ARGV[0]}"],start_no: 0},
  {names: ["#{ARGV[1]}"],start_no: 10000},
  {names: ["#{ARGV[2]}","#{ARGV[3]}"],start_no: 20000},
]

# Leer todos los archivos de escenario
Dir.chdir 's'
files = Dir.glob('*.txt').sort

scenes = []
files.each do |file|
  lines = []
  File.open(file,encoding: 'utf-8') do |f| #encoding cambiado, original era CP932:UTF-8
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

# Crear lista de hablantes
puts 'Lista de Personajes (Verificar carpeta de salida) '
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

# Numerar
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

# Generar el guion en formato de texto
File.open('script.txt','w',encoding: 'utf-8') do |f| #encoding cambiado, original era cp932
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

# Generar el guion en formato de texto
actresses.each do |actress|
  File.open("#{actress[:names][0]}script.txt",'w',encoding: 'utf-8') do |f|
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

# Insertar el texto del guion en un documento de Word
# [Texto a buscar]
# ;$●(*^13)
# [Texto de reemplazo]
# \1
#
# Luego, ajustar el formato del texto de reemplazo usando el botón de "Formato" para modificar el estilo del texto normal.
# (Por ejemplo, cambiar el tamaño de fuente a 9 puntos)
# Realizar la sustitución en todo el documento.
#
# [Texto a buscar]
# ;$■(*^13)
# [Texto de reemplazo]
# \1
#
# Luego, ajustar el formato del texto de reemplazo usando el botón de "Formato" para modificar el estilo del diálogo.
# (Por ejemplo, poner en negrita y tamaño de fuente 14 puntos)
# Realizar la sustitución en todo el documento.

# Generar guion solo con diálogos
actresses.each do |actress|
  File.open("#{actress[:names][0]}script(dialog-only).txt",'w',encoding: 'utf-8') do |f|
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
