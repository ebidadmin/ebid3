module MessagesHelper
  def nested_messages(messages)
    messages.map do |message, sub_messages|
      content_tag :li, (render 'messages/message_liner', :message => message) + (content_tag :ul, nested_messages(sub_messages), :class => 'nested' if sub_messages.present?)
    end.join.html_safe
  end
end
