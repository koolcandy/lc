import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SsoLoginUtil {
  static const String _ssoUrl = "https://sso.fzu.edu.cn/login";
  static const String _authUrl =
      "https://sso.fzu.edu.cn/oauth2.0/authorize?response_type=code&client_id=wlwxt&redirect_uri=http://aiot.fzu.edu.cn/api/admin/sso/getIbsToken";
  static const String _userAgent =
      'Mozilla/5.0 (iPad; CPU OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 appId/cn.edu.fzu.fdxypa appScheme/kysk-fdxy-app hengfeng/fdxyappzs appType/2 ruijie-facecamera';

  late final Dio _dio;
  late final CookieJar _cookieJar;

  SsoLoginUtil() {
    _cookieJar = CookieJar();
    _dio = Dio(BaseOptions(
      headers: {'User-Agent': _userAgent},
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
      contentType: Headers.formUrlEncodedContentType, // 默认为表单提交
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  /// AES-ECB 加密
  String _encryptPassword(String rawPassword, String keyBase64) {
    try {
      final key = encrypt.Key.fromBase64(keyBase64);
      // ECB 模式不需要 IV，但库要求传一个，这里传空或者任意长度皆可，内部会忽略
      final iv = encrypt.IV.fromLength(16); 

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: 'PKCS7'));
      final encrypted = encrypter.encrypt(rawPassword, iv: iv);
      
      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 正则提取
  String _extractMatch(String content, String pattern, String errorMsg) {
    final regExp = RegExp(pattern);
    final match = regExp.firstMatch(content);
    if (match == null || match.groupCount < 1) {
      throw Exception(errorMsg);
    }
    return match.group(1)!;
  }

  /// 执行登录流程
  Future<String> loginAndGetToken(String username, String password) async {
    try {
      // 1. 获取登录页面 HTML，提取 crypto Key 和 execution
      final pageResponse = await _dio.get(_ssoUrl);
      final html = pageResponse.data.toString();

      final crypto = _extractMatch(html, r'"login-croypto">(.*?)<', '无法提取密钥 (crypto)');
      final execution = _extractMatch(html, r'"login-page-flowkey">(.*?)<', '无法提取 Execution Key');
      
      // 注意：CookieManager 会自动处理 Set-Cookie (SESSION)，无需手动提取

      // 2. 加密密码 和 captcha_payload
      final encryptedPassword = _encryptPassword(password, crypto);
      final encryptedPayload = _encryptPassword('{}', crypto);

      // 3. 提交登录表单
      final loginData = {
        'username': username,
        'type': 'UsernamePassword',
        '_eventId': 'submit',
        'geolocation': '',
        'execution': execution,
        'captcha_code': '',
        'croypto': crypto,
        'password': encryptedPassword,
        'captcha_payload': encryptedPayload,
      };

      final loginResponse = await _dio.post(
        _ssoUrl,
        data: loginData,
        options: Options(
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false, // 禁止自动重定向，以便检查是否登录成功
            validateStatus: (status) => status! < 500),
      );

      // 4. 验证登录是否成功
      // 成功通常会返回 302 重定向，或者 Set-Cookie 中包含 SOURCEID_TGC
      final cookies = await _cookieJar.loadForRequest(Uri.parse(_ssoUrl));
      final hasTgc = cookies.any((c) => c.name == 'SOURCEID_TGC');

      if (!hasTgc) {
        // 如果没有 TGC Cookie，说明登录失败，尝试从页面解析错误信息
        if (loginResponse.statusCode == 200) {
           // 还在登录页，说明失败
           if (loginResponse.data.toString().contains("用户名或密码错误")) {
             throw Exception('学号或密码错误');
           }
           if (loginResponse.data.toString().contains("验证码")) {
             throw Exception('系统检测需要验证码，请稍后再试或使用网页版');
           }
        }
        throw Exception('登录失败，未获取到 TGC Cookie');
      }

      // 5. 使用 Cookie 获取 Token (请求 authorize 接口)
      // 这次要允许重定向，最终 URL 会包含 token
      final authResponse = await _dio.get(
        _authUrl,
        options: Options(followRedirects: true), // 必须跟随重定向
      );

      // 6. 从最终 URL 中提取 Token
      // Dio 会将最终重定向后的 URL 放在 response.realUri 中
      final finalUrl = authResponse.realUri.toString();
      
      if (finalUrl.contains('token=')) {
        // 简单提取 token
        final token = _extractMatch(finalUrl, r'token=([^&]+)', '最终 URL 中未找到 Token');
        return token;
      } else {
        throw Exception('重定向 URL 异常: $finalUrl');
      }

    } on DioException catch (e) {
      throw Exception('网络请求错误: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}