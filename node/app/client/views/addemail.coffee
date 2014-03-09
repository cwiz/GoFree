AddEmail = Backbone.View.extend
  el: '#l-content'

  initialize: ->
    @formEl = @$el.find('.p-a-form')
    @inputEl = @formEl.find('input')

    @formEl.m_formValidate()

    app.log('[app.views.AddEmail]: initialize')

  events:
    'valid .p-a-form':         'submitEmail'

  submitEmail: (evt, e)->
    app.e(e)

    email = $.trim(@inputEl.val())
    $.ajax(
      url: app.api.email_auth + email
      type: 'get'
      success: =>
        # give me journey hash or redirect yourself
        window.location.reload()
      )


app.views.AddEmail = AddEmail
