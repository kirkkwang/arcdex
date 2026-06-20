# frozen_string_literal: true

module Arcdex
  module Bulbapedia
    # Minimal MediaWiki wikitext helpers: brace-aware template extraction and
    # value cleaning.  Bulbapedia's TCG Pocket pages are rigorously templated,
    # so we only need to pull params out of named templates rather than parse
    # the full grammar.
    module Wikitext
      module_function

      # Return an array of param hashes, one per `{{name ...}}` occurrence.
      # Param hashes are { 'key' => 'value' } for `|key=value` pairs, plus
      # '_positional' => [..] for bare `|value` params (e.g. expansion headers).
      def templates(text, name)
        needle = "{{#{name}"
        results = []
        i = 0
        while i < text.length
          start = text.index(needle, i)
          break unless start

          after = text[start + needle.length]
          # boundary so "Pokémon" doesn't match "Pokémon/Pocket" etc.
          unless after.nil? || after.match?(/[\s|}]/)
            i = start + needle.length
            next
          end
          stop = matching_close(text, start)
          break if stop.nil? # unterminated template; nothing reliable left to parse

          results << params(text[(start + 2)...(stop - 2)])
          i = stop
        end
        results
      end

      # First matching template's params, or nil.
      def template(text, name)
        templates(text, name).first
      end

      # Index just past the `}}` that closes the `{{` at `open`, or nil if the
      # template is never closed.
      def matching_close(text, open)
        depth = 0
        j = open
        len = text.length
        while j < len
          if text[j, 2] == '{{'
            depth += 1
            j += 2
          elsif text[j, 2] == '}}'
            depth -= 1
            j += 2
            return j if depth.zero?
          else
            j += 1
          end
        end
        nil
      end

      # Split template inner text on top-level `|` (ignoring nested {{ }} / [[ ]]).
      def params(inner)
        parts = []
        buf = +''
        depth = 0
        i = 0
        len = inner.length
        while i < len
          two = inner[i, 2]
          if ['{{', '[['].include?(two)
            depth += 1
            buf << two
            i += 2
          elsif ['}}', ']]'].include?(two)
            depth -= 1
            buf << two
            i += 2
          elsif inner[i] == '|' && depth.zero?
            parts << buf
            buf = +''
            i += 1
          else
            buf << inner[i]
            i += 1
          end
        end
        parts << buf

        hash = {}
        positional = []
        parts[1..].each do |part|
          if part.include?('=')
            key, value = part.split('=', 2)
            hash[key.strip] = value.strip
          else
            stripped = part.strip
            positional << stripped unless stripped.empty?
          end
        end
        hash['_positional'] = positional unless positional.empty?
        hash
      end

      # Energy symbols `{{e|Lightning}}{{e|Colorless}}` -> ['Lightning','Colorless'].
      def energy(value)
        return [] if value.nil?

        value.scan(/\{\{e\|([^}|]+)\}\}/i).flatten.map(&:strip)
      end

      # Reduce wikitext markup in a free-text value to plain text.
      def clean(value)
        return nil if value.nil?

        text = value.dup
        text.gsub!(/\{\{e\|([^}|]+)\}\}/i, '\1') # energy
        text.gsub!(/\{\{(?:TCGP|TCG|ct|m|p|g|DL)\|([^}|]+)\}\}/i, '\1') # link-ish templates
        text.gsub!(/\[\[[^\]|]*\|([^\]]+)\]\]/, '\1') # [[target|label]] -> label
        text.gsub!(/\[\[([^\]]+)\]\]/, '\1') # [[label]] -> label
        text.gsub!(/'''?/, '') # bold/italic
        text.gsub!(/<[^>]+>/, '') # stray html tags
        text.gsub!(/\s+/, ' ') # collapse whitespace
        text.gsub!(/\{\{(.+?)\}\}/) do # strips handlebars
          parts = $1.split('|')
          parts.first == 'TCG ID' ? parts[2] : parts.last
        end

        text = text.strip
        text.empty? ? nil : text
      end
    end
  end
end
