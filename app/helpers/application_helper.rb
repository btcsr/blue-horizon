# frozen_string_literal: true

# General view helpers
module ApplicationHelper
  def sidebar_menu_items(advanced=Rails.configuration.x.advanced_mode)
    Rails.configuration.x.menu_items[advanced]
  end

  def sidebar_menu_item(path_key)
    text = t("sidebar.#{path_key}")
    icon = Rails.configuration.x.sidebar_icons[path_key]
    url = "/#{path_key}"

    content = [
      content_tag(:i, icon, class: ['eos-icons', 'md-18']),
      content_tag(:span, text, class: 'collapse')
    ].join(' ').html_safe

    active_link_to(content, url,
      class: 'list-group-item',
      data:  { toggle: 'tooltip', placement: 'right', original_title: text }
    )
  end

  def bootstrap_flash
    flash.collect do |type, message|
      # Skip empty messages
      next if message.blank?

      context = case type.to_sym
      when :notice
        :success
      when :alert
        :warning
      when :error
        :danger
      else
        :secondary
      end
      render 'layouts/flash', context: context, message: message
    end.join.html_safe
  end

  def custom_image_exists?(filename)
    base_path = Rails.root.join('vendor', 'assets', 'images')
    File.exist?(File.join(base_path, "#{filename}.svg"))   ||
      File.exist?(File.join(base_path, "#{filename}.png")) ||
      File.exist?(File.join(base_path, "#{filename}.jpg"))
  end
end
