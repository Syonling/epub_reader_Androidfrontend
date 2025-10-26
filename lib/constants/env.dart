class Env {
  // 开发环境：使用Mac本地IP
  static const String devBackendUrl = 'http://192.168.11.35:5001';
  
  // 生产环境：使用服务器IP
  static const String prodBackendUrl = 'http://YOUR_SERVER_IP:5001';
  
  // 自动检测当前环境
  static const bool isDevelopment = true; // 改成false切换到生产环境
  
  static String get backendUrl => isDevelopment ? devBackendUrl : prodBackendUrl;
}



