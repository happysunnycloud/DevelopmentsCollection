unit Net.Constants;

interface

const
  PROTOCOL_VERSION = '0.0';
  SERVER_PORT = 1081;
  CONNECT_TIMEOUT = 2000;
  READ_TIMEOUT = -1; // -1 = Вечно ожидать поступления данных
  LOGIN_TIMEOUT = 2000;
  PING_TIMEOUT = 2000;
  DISCONNECT_TIMEOUT = 2000;
  HEART_BEAT_INTERVAL = 1000;
  USER_LOGIN = 'User0123';
  USER_PASSWORD = 'Password';

implementation

end.
