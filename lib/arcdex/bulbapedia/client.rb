# frozen_string_literal: true

require 'http'

module Arcdex
  module Bulbapedia
    # Thin MediaWiki API client for Bulbapedia. Batches card wikitext fetches
    # (≤50 titles/request), resolves redirects/normalization, and is polite
    # (descriptive UA, maxlag, serial requests, exponential-backoff retry).
    class Client
      API = 'https://bulbapedia.bulbagarden.net/w/api.php'
      USER_AGENT = 'arcdex/1.0 (https://arcdex.dev; kirk@notch8.com) card-catalog'
      BATCH = 50
      MAX_RETRIES = 8
      MAX_CATEGORY_PAGES = 50 # continuation safety cap (Pocket has ~1 page)

      # Raised for retryable conditions (network error, 5xx, maxlag).
      class TransientError < StandardError; end

      # Wikitext of a single page (e.g. an expansion page).
      def page_wikitext(title)
        data = get(action: 'query', prop: 'revisions', rvprop: 'content', rvslots: 'main',
                   redirects: 1, titles: title)
        page = data.dig('query', 'pages')&.values&.first
        page&.dig('revisions', 0, 'slots', 'main', '*')
      end

      # { requested_title => wikitext|nil } for many pages, batched.
      def pages_wikitext(titles)
        result = {}
        titles.each_slice(BATCH) do |slice|
          query = get(action: 'query', prop: 'revisions', rvprop: 'content', rvslots: 'main',
                      redirects: 1, titles: slice.join('|'))['query'] || {}

          normalized = map_pairs(query['normalized'])
          redirects  = map_pairs(query['redirects'])
          by_title = {}
          (query['pages'] || {}).each_value do |page|
            by_title[page['title']] = page.dig('revisions', 0, 'slots', 'main', '*')
          end

          slice.each do |title|
            resolved = redirects[normalized[title] || title] || normalized[title] || title
            result[title] = by_title[resolved]
          end
        end
        result
      end

      # All page titles in a category (follows continuation).
      def category_members(category)
        members = []
        continuation = {}
        MAX_CATEGORY_PAGES.times do
          data = get(action: 'query', list: 'categorymembers', cmtitle: category,
                     cmlimit: 500, cmtype: 'page', **continuation)
          members.concat((data.dig('query', 'categorymembers') || []).pluck('title'))
          break unless data['continue']

          continuation = data['continue'].transform_keys(&:to_sym)
        end
        members
      end

      # Direct URL for a File: page (e.g. "B3a Set Logo EN.png").
      def image_url(filename)
        data = get(action: 'query', titles: "File:#{filename}", prop: 'imageinfo', iiprop: 'url')
        page = data.dig('query', 'pages')&.values&.first
        page&.dig('imageinfo', 0, 'url')
      end

      private

      def map_pairs(list)
        (list || []).each_with_object({}) { |pair, acc| acc[pair['from']] = pair['to'] }
      end

      def get(params)
        params = params.merge(format: 'json', maxlag: 5)
        retries = 0
        begin
          response = HTTP.headers('User-Agent' => USER_AGENT).get(API, params: params)
          raise TransientError, "HTTP #{response.status}" unless response.status.success?

          json = response.parse
          if (error = json['error'])
            # maxlag is transient (server busy) → retry; other API errors are
            # permanent (bad request) → surface immediately rather than retrying.
            raise TransientError, 'maxlag' if error['code'] == 'maxlag'

            raise "MediaWiki API error: #{error['code']}: #{error['info']}"
          end

          json
        rescue TransientError, HTTP::Error => e
          retries += 1
          raise e if retries > MAX_RETRIES

          sleep(2**(retries - 1))
          retry
        end
      end
    end
  end
end
