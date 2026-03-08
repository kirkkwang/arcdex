# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Gallery::DocumentComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Blacklight::Gallery::DocumentComponentDecorator

      attr_reader :with_thumbnail_options

      def thumbnail
        @thumbnail
      end

      def thumbnail=(value)
        @thumbnail = value
      end

      def with_thumbnail(image_options:)
        @with_thumbnail_options = image_options
      end

      # Original before_render does nothing in this stub
      def before_render; end
    end
  end

  describe '#before_render' do
    subject(:component) { stub_class.new }

    context 'when thumbnail is blank' do
      before { component.thumbnail = nil }

      it 'calls with_thumbnail with lazy loading' do
        component.before_render
        expect(component.with_thumbnail_options).to include(loading: 'lazy')
      end

      it 'adds the img-thumbnail class' do
        component.before_render
        expect(component.with_thumbnail_options).to include(class: 'img-thumbnail')
      end
    end

    context 'when thumbnail is already set' do
      before { component.thumbnail = 'existing thumbnail' }

      it 'does not call with_thumbnail' do
        component.before_render
        expect(component.with_thumbnail_options).to be_nil
      end
    end
  end
end
