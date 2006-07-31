class SeleniumOnRails::Selenese
end
ActionView::Base.register_template_handler 'sel', SeleniumOnRails::Selenese


class SeleniumOnRails::Selenese
  def initialize view
    @view = view
  end

  def render template, local_assigns
    name = (@view.assigns['page_title'] or local_assigns['page_title'])
    lines = template.strip.split "\n"
    html = ''
    html << extract_comments(lines)
    html << extract_commands(lines, name)
    html << extract_comments(lines)
    raise 'You cannot have comments in the middle of commands!' if next_line lines, :any
    html
  end

  private
    def next_line lines, expects
      while lines.any?
        l = lines.shift.strip
        next if (l.empty? and expects != :comment)
        comment = (l =~ /^\|.*\|$/).nil?
        if (comment and expects == :command) or (!comment and expects == :comment)
          lines.unshift l
          return nil
        end
        return l
      end
    end

    def extract_comments lines
      comments = ''
      while (line = next_line lines, :comment)
        comments << line + "\n"
      end
      if defined? RedCloth
        comments = RedCloth.new(comments).to_html
      else
        comments = simple_format comments
      end
      comments += "\n" unless comments.empty?
      comments
    end

    def extract_commands lines, name
      html = "<table>\n<tr><th colspan=\"3\">#{name}</th></tr>\n"
      while (line = next_line lines, :command)
        line = line[1..-2] #remove starting and ending |
        cells = line.split '|'
        raise 'There might only be a maximum of three cells!' if cells.length > 3
        html << '<tr>'
        (1..3).each do
          cell = cells.shift
          cell = (cell ? CGI.escapeHTML(cell.strip) : '&nbsp;')
          html << "<td>#{cell}</td>"
        end
        html << "</tr>\n"
      end
      html << "</table>\n"
    end

end