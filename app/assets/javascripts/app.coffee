require(["webjars!knockout.js", 'webjars!jquery.js', "/routes.js", "webjars!bootstrap.js"], (ko) ->

  messagesPerPage = 10

  /* Models for the messages page */
  class MessagesModel
    constructor: () ->
      self = @
      /* the list of messages */
      @messages = ko.observableArray()

      /* the messages field that messages are entered into */
      @messageField = ko.observable()

      /* the author field that messages are entered into */
      @messageAuthorField = ko.observable()

      /* the URL to fetch the next page of messages, if one exists */
      @nextMessagesUrl = ko.observable()

      /* the URL to fetch the previous page of messages, if one exists */
      @prevMessagesUrl = ko.observable()

      /* save a new message */
      @saveMessage = () ->
        @ajax(routes.controllers.MessageController.saveMessage(), {
          data: JSON.stringify({
            message: @messageField()
            author: @messageAuthorField()
          })
          contentType: "application/json"
        }).done(() ->
          $("#addMessageModal").modal("hide")
          self.messageField(null)
        )

      /* get the messages */
      @getMessages = () ->
        @ajax(routes.controllers.MessageController.getMessages(0, messagesPerPage))
          .done((data, status, xhr) ->
            self.loadMessages(data, status, xhr)
          )

      /* get the next page of messages */
      @nextMessages = () ->
        if @nextMessagesUrl()
          $.ajax({url: @nextMessagesUrl()}).done((data, status, xhr) ->
            self.loadMessages(data, status, xhr)
          )

      /* get the previous page of messages */
      @prevMessages = () ->
        if @prevMessagesUrl()
          $.ajax({url: @prevMessagesUrl()}).done((data, status, xhr) ->
            self.loadMessages(data, status, xhr)
          )

      /* like the message */
      @likeMessage = (message) ->
        self.ajax(routes.controllers.MessageController.likeMessage(message._id.$oid))

    /* Setup the given message so that some of it's properties can be observed */
    bindMessage: (message) ->
      message.likes = ko.observable(message.likes)

    /* Convenience ajax request function */
    ajax: (route, params) ->
      $.ajax($.extend(params, route))

    /* Handle the messages response */
    loadMessages: (data, status, xhr) ->
      data.forEach(@bindMessage)
      @messages(data)

      # Link handling for paging
      link = xhr.getResponseHeader("Link")
      if link
        next = /.*<([^>]*)>; rel="next".*/.exec(link)
        if next
          @nextMessagesUrl(next[1])
        else
          @nextMessagesUrl(null)
        prev = /.*<([^>]*)>; rel="prev".*/.exec(link)
        if prev
          @prevMessagesUrl(prev[1])
        else
          @prevMessagesUrl(null)
      else
        @nextMessagesUrl(null)
        @prevMessagesUrl(null)

  # Setup
  model = new MessagesModel
  ko.applyBindings(model)
  # Load messages data
  model.getMessages()

  /* Server Sent Events handling */
  events = new EventSource(routes.controllers.MainController.events().url)

  events.addEventListener("like", (e) ->
    id = JSON.parse(e.data)
    ko.utils.arrayForEach(model.messages(), (message) ->
      if (message._id.$oid == id)
        message.likes(message.likes() + 1)
    )
  )

  events.addEventListener("message", (e) ->
    # Only add the data to the list if we're on the first page
    if model.prevMessagesUrl() == null
      message = JSON.parse(e.data)
      model.bindMessage(message)
      model.messages.unshift(message)
      # Keep messages per page limit
      if model.messages().length > messagesPerPage
        model.messages.pop()
  , false)
)