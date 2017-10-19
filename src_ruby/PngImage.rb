# coding: UTF-8
require "zlib"

#RubyでPNG画像を書き出す簡易クラス
class PngImage

  #画像の初期化（1マス50*50px）
  def initialize(xMax, yMax)
    @width, @height = yMax * 50, xMax * 50
    line = (0...@width).map {|x| [0, 0, 0, 0] }
    @rawData = (0...@height).map {|y| line.clone}
  end

  #ペンの厚さの処理用
  def getRange(weight)
    if(weight % 2 == 0)
      (-weight/2+1)...weight/2
    else
      -weight/2...weight/2
    end
  end

  #線の描画
  def drawLine(from, dest, weight, color)
    dy = 99
    dy = (dest[1].to_f - from[1].to_f) / (dest[0].to_f - from[0].to_f) unless((dest[0].to_f - from[0].to_f) == 0.0)

    #傾きの緩やかな側を基準にする
    if(dy.abs > 1)
      #（x軸基準）
      if(dest[1] < from[1])
        dest, from = from, dest
      end
      x = from[0].to_f
      dx = 1
      dx = (dest[0].to_f - from[0].to_f) / (dest[1].to_f - from[1].to_f) unless((dest[1].to_f - from[1].to_f) == 0.0)
      (from[1].to_i...dest[1].to_i).each{|y|
        x += dx
        getRange(weight).each{|i|
          @rawData[y][x.to_i+i] = color if(0 <= x+i && x+i <= @height && 0 <= y && y <= @width)
        }
      }
    else
      #（y軸基準）
      if(dest[0] < from[0])
        dest, from = from, dest
      end
      y = from[1].to_f
      (from[0].to_i...dest[0].to_i).each{|x|
        y += dy
        getRange(weight).each{|i|
          @rawData[y.to_i+i][x] = color if(0 <= x && x < @height && 0 <= y+i && y+i < @width)
        }
      }
    end
  end

  #円弧の描画（始点・終点で使用）
  def drawCircle(point, weight, color)
    getRange(weight).each{|i|
      y = point[1].to_i + i
      range = Math.sqrt(weight ** 2 / 4 - (i.abs - 1) ** 2).to_i
      (-range...range).each{|j|
        x = point[0].to_i + j
        @rawData[y][x] = color if(0 <= x && x < @height && 0 <= y && y < @width)
      }
    }
  end

  #どどんとふの手書き形式のパスデータ（ペン情報含む）を書き込む
  def drawPath(draws)
    for draw in draws do
      pen = draw.shift
      weight = pen["weight"]
      if pen["type"] != "erase"
        color = [pen["color"] / 65536, pen["color"] / 256 % 256, pen["color"] % 256,255]
      else
        color = [0, 0, 0, 0]
      end

      previousPoint = draw.shift
      while point = draw.shift
        drawCircle(previousPoint, weight, color) #始点
        drawLine(previousPoint, point, weight, color)
        previousPoint = point
      end
      drawCircle(previousPoint, weight, color) #終点
    end
  end

  #PNGデータの構築用
  def chunk(type, data)
    [data.bytesize, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
  end

  #PNGデータにして書き出し
  def save(filepath)
    File.open(filepath, "wb") do |f|
      f.print("\x89PNG\r\n\x1a\n")
      f.print(chunk("IHDR", [@width, @height, 8, 6, 0, 0, 0].pack("NNCCCCC")))
      imgData = @rawData.map {|line| ([0] + line.flatten).pack("C*") }.join
      f.print(chunk("IDAT", Zlib::Deflate.deflate(imgData)))
      f.print(chunk("IEND", ""))
    end
  end
end
