# frozen_string_literal: true

# General view helpers
module ApplicationHelper
  def sidebar_menu_items
    Rails.configuration.x.menu_items
  end

  def bootstrap_flash
    flash.collect do |type, message|
      # Skip empty messages
      next if message.blank?

      render 'layouts/flash',
        context: Rails.configuration.x.flash_context[type.to_sym],
        message: message
    end.join.html_safe
  end

  def bootstrap_unsupported(sidebar_key)
    if Rails.configuration.x.unsupported_sidebar_items.include?(sidebar_key.to_s)
      return render('layouts/unsupported').html_safe
    end
  end

  def custom_image_exists?(filename)
    base_path = Rails.root.join('vendor', 'assets', 'images')
    File.exist?(File.join(base_path, "#{filename}.svg"))   ||
      File.exist?(File.join(base_path, "#{filename}.png")) ||
      File.exist?(File.join(base_path, "#{filename}.jpg"))
  end

  def tip_icon
    tag.i('lightbulb_outline', class: 'eos-icons text-warning align-middle',
                               title: 'Tip',
                               data:  { toggle: 'tooltip' }
    )
  end

  def source_footer
    render('layouts/source_footer')
      .gsub("\n", ' ').strip
      .gsub("'", '"')
      .html_safe
  end

  def markdown(text, escape_html: true)
    return '' if text.blank?

    markdown_options = {
      autolink:            true,
      space_after_headers: true,
      no_intra_emphasis:   true,
      fenced_code_blocks:  true,
      strikethrough:       true,
      superscript:         true,
      underline:           true,
      highlight:           true,
      quote:               true
    }
    render_options = {
      filter_html: false,
      no_images:   false,
      no_styles:   true
    }
    render_options[:escape_html] = true if escape_html

    # Redcarpet doesn't remove HTML comments even with `filter_html: true`
    # https://github.com/vmg/redcarpet/issues/692
    uncommented_text = text.gsub(/<!--(.*?)-->/, '')

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(render_options),
      markdown_options
    )
    markdown.render(uncommented_text).html_safe
  end

  def loading_icon(hide: true)
    tag.img(
      src:   asset_path('bubble_loading.svg'),
      alt:   t('tooltips.loading'),
      title: t('tooltips.loading'),
      class: 'eos-48 centered',
      style: ('display: none;' if hide),
      id:    'loading'
    )
  end

  def pretty_json(raw_json_string)
    JSON.pretty_generate(JSON.parse(raw_json_string))
  rescue StandardError
    ''
  end

  def get_url(request_id)
    case controller_name
    when 'dashboards'
      dashboard_path(request_id)
    when 'resources'
      resources_path
    end
  end

  def get_url_from_menu(request_id, menu_item)
    case controller_name
    when 'dashboards'
      get_dashboard_url(request_id, menu_item).present? if request_id
    when 'resources'
      '/resources' if menu_item['key'] == 'resources'
    end
  end

  def top_menu_item_class(menu_item, request_id, format_values)
    (url = menu_item['url'] % format_values) if format_values
    selected = get_url_from_menu(request_id, menu_item)
    "submenu-item#{' disabled' unless url}#{' selected' if selected}"
  end

  def top_menu_items(request_id=nil, format_values=nil)
    tags = Rails.configuration.x.top_menu_items.collect do |menu_item|
      (url = menu_item['url'] % format_values) if format_values
      link_to(
        t("menu.#{menu_item['key']}"),
        (url || '#'),
        id:     menu_item['key'],
        # The selected class must be obtained using code, as we don't follow the
        # the hierarchical address logic in the submenu items
        class:  top_menu_item_class(menu_item, request_id, format_values),
        target: ('_blank' if menu_item['target_new_window'])
      )
    end
    tags.join.html_safe
  end

  def container_type
    if ['dashboards'].include? controller_name
      'grafana-container'
    else
      'container'
    end
  end
end
