module Docs
  class Rust
    class EntriesFilter < Docs::EntriesFilter

      def get_name
        if slug.start_with?('book')
          name = at_css('main h1', 'main h2')

          if slug.start_with?('book/appendix')
            return name ? name.content : 'Appendix'
          end

          ch1 = slug[/ch(\d+)-(\d+)/, 1] || '00'
          ch2 = slug[/ch(\d+)-(\d+)/, 2] || '00'
          name ? "#{ch1}.#{ch2}. #{name.content}" : 'Introduction'
        elsif slug.start_with?('reference')
          at_css('main h1').content
        elsif slug == 'error_codes/error-index'
          'Compiler Errors'
        elsif slug.start_with?('error_codes')
          slug.split('/').last.upcase
        else
          at_css('main h1').at_css('button')&.remove
          name = at_css('main h1').content.remove(/\A.+\s/).remove('⎘')
          path = slug.split('/')
          if path.length == 2
            # Anything in the standard library but not in a `std::*` module is
            # globally available, not `use`d from the `std` crate, so we don't
            # prepend `std::` to their name.
            return name
          end
          path.pop if path.last == 'index'
          mod = path[0..-2].join('::')
          name.prepend("#{mod}::") unless name.start_with?(mod)
          name
        end
      end

      PRIMITIVE_SLUG = /\A(\w+)\/(primitive)\./

      def get_type
        if slug.start_with?('book')
          'Guide'
        elsif slug.start_with?('reference')
          'Reference'
        elsif slug.start_with?('error_codes')
          'Compiler Errors'
        else
          path = slug.split('/')
          # Discard the filename, and use the first two path components as the
          # type, or one if there is only one. This means anything in a module
          # `std::foo` or submodule `std::foo::bar` gets type `std::foo`, and
          # things not in modules, e.g. primitive types, get type `std`.
          path[0..-2][0..1].join('::')
        end
      end

      def additional_entries
        if slug.start_with?('book') || slug.start_with?('reference') || slug.start_with?('error_codes')
          []
        else
          css('.method')
            .each_with_object({}) { |node, entries|
              name = node.at_css('a.fn').try(:content)
              next unless name
              name.prepend "#{self.name}::"
              entries[name] ||= [name, node['id']]
            }.values
        end
      end

    end
  end
end
