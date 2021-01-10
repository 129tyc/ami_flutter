const eol = '\r\n';

enum MessageType {
  response,
  event,
  action,
  unknown,
}

enum HandleStatus {
  idle,
  reading,
  truncated,
  done,
}
