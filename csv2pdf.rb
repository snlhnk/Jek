require 'csv'
require 'prawn'

class Person
  attr_accessor :name, :title, :zip, :addr1, :addr2,\
                :family1, :title1, :family2, :title2

  def initialize(csv_row)
    @kana = csv_row[0]
    @name = csv_row[1]
    @title = csv_row[2]
    @zip = csv_row[3]
    @addr1 = csv_row[4]
    @addr2 = csv_row[5]
    @family1 = csv_row[6]
    @title1 = csv_row[7]
    @family2 = csv_row[8]
    @title2 = csv_row[9]
  end

  def address
    if not @addr1
      nil
    else
      @addr1 + (@addr2? " / " +@addr2: "")
    end
  end
end

class Pdf < Prawn::Document

  def initialize
    super(page_size: [283,420], page_layout: :portrait,\
          margin: [32.6, 85, 35.4, 73.7])
    @p_name_ofs = 0
    @f_name = nil
  end

  def stroke_address(person)
    zip = person.zip.gsub("-","").split("")
    7.times do |i|
      x = 52.4 + i * 19.84
    end
    font(locate_font("carlito"))
    font_size(20)
    7.times do |i|
      x = 56.4 + i * 19.84
      bounding_box([x, 351.8], width: 16.2, height: 22.7) do
        text zip[i]
      end
    end

    render_addr(person.addr1, 160, 320)
    render_addr(person.addr2, 130, 300) if person.addr2
    render_name(person.name, person.title, 65)
    render_name(person.family1, person.title1, 33) if person.family1
    render_name(person.family2, person.title2, 1) if person.family2

    # hidden information
    bounding_box([0, 340], width: 250, height: 400) do
      font(locate_font("j-min"))
      font_size(7)
      text "*#{person.name}", color: "ffffff"
      text "*#{person.title}", color: "ffffff"
      text "*#{person.zip}", color: "ffffff"
      text "*#{person.addr1}", color: "ffffff"
      text "*#{person.addr2}", color: "ffffff"
      text "*#{person.family1}", color: "ffffff"
      text "*#{person.title1}", color: "ffffff"
      text "*#{person.family2}", color: "ffffff"
      text "*#{person.title2}", color: "ffffff"
    end
  end

  private

  def locate_font(font)
    case font
    when "j-min"
      "/usr/local/share/font-mplus-ipa/fonts/ipamp.ttf"
    when "j-goth"
      "/usr/local/share/font-mplus-ipa/fonts/ipagp.ttf"
    when "j-kaisho"
      "./TKaisho-GT01_0.ttf"
    else
      "/usr/local/share/fonts/Carlito/Carlito-Regular.ttf"
    end
  end

  def config_font(str_array) # return size, pitch
    if str_array.length < 16
      return 25, 20
    elsif str_array.length < 19
      return 22, 17
    else
      return 19, 15
    end
  end

  def tategaki(str, x_ofs, y_ofs, size, pitch)
    yy = y_ofs
    str.each do |s|
      case s
      when 'ー', '-'
        draw_text("－", at: [x_ofs+size/9, yy], rotate: -90)
        yy -= pitch
      when 'ァ', 'ィ', 'ゥ', 'ェ', 'ォ', 'ッ', 'ャ', 'ュ', 'ョ',
           'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ', 'っ', 'ゃ', 'ゅ', 'ょ'
        bounding_box([x_ofs+size/8, yy+size/8], width: size, height: size) do
          text s
          yy -= pitch 
        end
      when ' ', '　'
        yy -= pitch / 3
      when '〇'
        tmp_size = size * 7 / 8
        font_size(tmp_size)
        bounding_box([x_ofs + size / 9, yy - size / 10], width: tmp_size, height: tmp_size) do
          text s
          yy -= pitch
        end
        font_size(size)
      else
        bounding_box([x_ofs, yy], width: size, height: size) do
          text s
          yy -= pitch
        end
      end
    end
    return yy #書き終わりの位置
  end

  def to_kanji(s)
  s.tr!('0-9a-zA-Z', '０-９ａ-ｚＡ-Ｚ')
  s = s.gsub('１','一').gsub('２','二').gsub('３','三').gsub('４','四')
  s = s.gsub('５','五').gsub('６','六').gsub('７','七').gsub('８','八')
  s = s.gsub('９','九').gsub('０','〇')
  end

  def render_addr(ad, x_ofs, y_ofs)
    addr = to_kanji(ad).split("")
    size, pitch = config_font(addr)
    font(locate_font("j-kaisho"))
    font_size(size)
    tategaki(addr, x_ofs, y_ofs, size, pitch)
  end

  def split_name(name)
    retrun nil, nil if not name
    n = name.split(/ |　/)
    f_name = n[0].split("")
    if n.length > 1
      p_name = n[1].split("")
    else
      p_name = f_name
      f_name = nil
    end
    return f_name, p_name
  end

  def render_name(name, title_, x_ofs)
    f_name, p_name = split_name(name)
    title = title_.split("")
    size, pitch = 35, 30
    break_pitch = pitch * 0.3
    start_from = 300 #270
    font(locate_font("j-kaisho"))
    font_size(size)

    if f_name
      yy = tategaki(f_name, x_ofs, start_from, size, pitch)
      @p_name_ofs = yy - break_pitch
    end
    yy = tategaki(p_name, x_ofs, @p_name_ofs, size, pitch)
    tategaki(title, x_ofs, yy - break_pitch, size, pitch)
  end
end

if ($0 == __FILE__)
  source = ARGV.shift
  csv = CSV.open(source)

  people = Array.new
  csv.each do |c|
    people << Person.new(c)
  end

  pdf = Pdf.new

  n = people.length
  people.each do |p|
    pdf.stroke_address(p)
    n -= 1
    pdf.start_new_page if n > 0
  end

  pdf.render_file("./output.pdf")
end
