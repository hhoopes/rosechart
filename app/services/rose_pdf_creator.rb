class RosePdfCreator
  attr_reader :size, :width, :gens, :font_size, :people, :doc, :input_file, :id_1, :id_2, :center

  def initialize(file, gens, size: 600, font_size: 6, font_type: "Perpetua.ttf", id_1: "I9770", id_2: "I13761" )
    @size = size
    @gens = gens ||= 5
    @width = (size / (2 * (gens + 1)))
    @font_size = font_size
    @center = size / 2
    @people = Array.new(gens)
    @doc = Prawn::Document.new(page_size: [size, size],
                               margin: 0,
                               font_size: font_size,
                               font: font_type)
    @input_file = Gedcom.file(file, "r")
    @id_1 = id_1
    @id_2 = id_2
  end

  def generate_pdf
    draw_background
    generate_people

    # For each generation, find the longest name and calculate the maximum font that will fit in the cell.
    last_font_size = 99
    0.upto(gens - 1) do | gen |
      maxPos = calculate_max_position(gen)
      name_data = people[gen][maxPos].names()[0]
      name = name_data.given.first + " " + name_data.surname.first
      print "Largest Name in gen #{gen} is "+name+"\n"
      # Keep trying bigger fonts till one doesn't fit
      fontSize = calculate_max_font(gen, name)
      # Don't allow fonts to get bigger.  It looks weird
      if (fontSize > last_font_size)
        fontSize = last_font_size
      end
      last_font_size = fontSize
      print "Font for gen #{gen} is #{fontSize}\n"
      #Actually add names to chart
      doc.font_size(fontSize)
      0.upto(2**(gen+1)-1) do | pos |
        printIndividual(people[gen][pos], gen, pos)
      end
    end
    # Render the prepared @document
    doc.render_file("public/downloads/Test2.pdf")

  end

  def calculate_max_font(gen, name)
    font_size = 1
    text_fits = true
    while (text_fits)
      doc.font_size(font_size)
      text_width = doc.width_of(name)
      allowed_width = gen == 0 ? 1.25 * width : calculate_allowed_width(gen)
      if (text_width > allowed_width)
        print "#{text_width} is greater than #{allowed_width}\n"
        font_size = font_size - 1
        text_fits = false
      else
        font_size = font_size + 1
      end
    end
    font_size
  end

  def calculate_allowed_width(gen)
    angle_inc = (2 * Math::PI / (2**(gen+1)))
    allowedWidth = Math.sin(angle_inc)*(gen+0.5)*(width)
  end

  def calculate_max_position(gen)
    maxWidth, maxPos = 0
    0.upto(2**(gen+1)-1) do | pos |
      name_data = people[gen][pos].names()[0]
      name = name_data.given.first + " " + name_data.surname.first
      textWidth = doc.width_of(name)
      if (textWidth > maxWidth)
        maxWidth = textWidth
        maxPos = pos
      end
    end
    maxPos
  end

  def walkTree (individual, gen, position)
    #printIndividual(individual, gen, position)
    if @people[gen].nil?
      @people[gen] = Array.new(2**(gen+1))
    end
    @people[gen][position] = individual
    if (gen > gens)
      return
    end
    if (individual.parents_family && individual.parents_family[0].husband())
      walkTree(individual.parents_family[0].husband(), gen+1, position*2)
    end
    if (individual.parents_family && individual.parents_family[0].wife())
      walkTree(individual.parents_family[0].wife(), gen+1, position*2+1)
    end
  end

  def printIndividual (individual, gen, position)
    name_data = individual.names()[0]
    name = name_data.given.first + " " + name_data.surname.first
    lifespan = generate_lifespan(individual)

    angleInc = 360.0/(2**(gen+1))
    angle = (angleInc*position)
    # Rotation defaults to counter clockwise so invert
    # Add half a segment rotation to center the text in the cell
    doc.rotate( -(angle+angleInc/2), origin: [center, center]) do
      # Offset the text by half the text width to center in cell
      # And "up" from the rotated origin by width times current generation
      #  plus half a width to center in cell
      textHeight = doc.font.height()
      textWidth = doc.width_of(name)
      doc.draw_text(name, at: [center-(textWidth/2),center+(gen+0.5)*width])
      textWidth = doc.width_of(lifespan)
      doc.draw_text(lifespan, at: [center-(textWidth/2),center+(gen+0.5)*width-textHeight])
    end
  end

  def generate_lifespan(individual)
    if (individual.birth && individual.birth()[0].date_record)
      birth_year = individual.birth()[0].date_record[0].date_value[0][-4..-1]
    else
      birth_year = ""
    end
    if (individual.death && individual.death()[0].date_record)
      death_year = individual.death()[0].date_record[0].date_value[0][-4..-1]
    else
      death_year = ""
    end
    birth_year + " - " + death_year + "\n"
  end

  def generate_people
    t = input_file.transmissions[0]
    parent_1, parent_2 = t.find(:individual, id_1), t.find(:individual, id_2)
    walkTree(parent_1, 0, 0)
    walkTree(parent_2, 0, 1)
  end

  def draw_background
    0.upto(gens-1) do | gen |
      doc.stroke_circle [center,center], (gen+1)* width
      segs = 2**(gen + 1)
      angleInc = 2 * Math::PI / segs
      1.upto(segs) do | seg |
        xstart = center + Math.sin(angleInc*seg)*(gen)*(width)
        xend = center + Math.sin(angleInc*seg)*(gen+1)*(width)
        ystart = center + Math.cos(angleInc*seg)*(gen)*(width)
        yend = center + Math.cos(angleInc*seg)*(gen+1)*(width)
        doc.line( [xstart, ystart], [xend, yend] )
        doc.stroke
      end
    end
  end

end
