# Use local alias
$ = jQuery

window.portfolio =
  append_item: (images) ->
    $.each images, (index, image) ->
      # Increment current count for existing 
      current_count = parseInt($('#page_images').attr('data-current-count'))
      $('#page_images').attr('data-current-count', current_count + 1)

      image_id = $(image).attr('id').replace 'image_', ''
      image_src = $(image).attr('data-medium')
      new_image = $('li.item_field.blank:first').clone() # Clone li

      new_image.find('.attributes input.image_id').val image_id # Set input image_id value = image_id
      new_image.find('.attributes input.image_id').attr('name', 'gallery[items_attributes][' + current_count + '][image_id]')
      new_image.find('.attributes textarea.item_caption').attr('name', 'gallery[items_attributes][' + current_count + '][caption]')
      # Create thumbnail
      $('<img/>', {src: image_src}).appendTo(new_image.find('.thumb'))

      new_image
        .attr('id', "image_#{image_id}") # Update id
        .appendTo('#page_images') # Append to list
        .removeClass('blank')

$ ->
  page_options.init(false, '', '')
  $('#page_images').sortable()

  # Moving textarea causes webkit browsers to freak out.
  $('#content #page_images li textarea:hidden').each (index) ->
    old_name = $(this).attr('name')
    $(this).attr('data-old-id', $(this).attr('id'))
    $(this).attr('name', 'ignore_me_' + index)
    $(this).attr('id', 'ignore_me_' + index)

    hidden = $('<input>').addClass('caption')
      .attr('type', 'hidden')
      .attr('name', old_name)
      .attr('id', $(this).attr('data-old-id'))
      .val($(this).val())

    $(this).parents('li').first().append(hidden)
  

  $(document).on 'click', '#page_images li .delete_item', -> 
    if confirm("Are you sure you want to remove this image?")
      $(this).parents('li').remove()
    else
      false

  $(document).on 'click', '#page_images li .caption', ->
    (list_item = $(this).parents('li').first()).addClass('current_caption_list_item')
    textarea = list_item.find('.textarea_wrapper_for_wym > textarea');

    textarea.after($("<div class='form-actions'><div class='form-actions-left'><a class='button'>Done / Finis</a></div></div>"))
    textarea.parent().dialog
      title: "Add Caption"
      modal: true
      resizable: false
      autoOpen: true
      width: 928
      height: 530

    $('.ui-dialog:visible .ui-dialog-titlebar-close, .ui-dialog:visible .form-actions a.button').on(
      'click',
      $.proxy(
        (e) ->
          # Update editor
          $(this).data('wymeditor').update()
          $(this).removeClass('wymeditor').removeClass('active_rotator_wymeditor')

          $this_parent = $(this).parent()
          $this_parent.appendTo('li.current_caption_list_item').dialog('close').data('dialog', null)
          $this_parent.find('.form-actions').remove()
          $this_parent.find('.wym_box').remove()
          $this_parent.css('height', 'auto')
          $this_parent.removeClass('ui-dialog-content').removeClass('ui-widget-content')

          $('li.current_caption_list_item').removeClass('current_caption_list_item')

          $('.ui-dialog, .ui-widget-overlay:visible').remove()

          $('#' + $(this).attr('data-old-id')).val($(this).val())
        , textarea)
      )

    textarea.addClass('wymeditor active_rotator_wymeditor widest').wymeditor(wymeditor_boot_options)


