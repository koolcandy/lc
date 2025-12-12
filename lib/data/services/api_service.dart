import 'package:dio/dio.dart';
import 'package:lc/utils/seat_mapping.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../models/seat_status.dart';
import '../models/seat_time.dart';

class ApiService {
  // 单例模式：确保全局只用一个 Dio 实例
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static const String _baseUrl = 'https://aiot.fzu.edu.cn/api/ibs';
  static const String _tokenKey = 'LEARNING_CENTER_TOKEN_KEY'; // 对应原项目的 Key

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          // 照搬原项目的 User-Agent，防止被拦截
          'User-Agent':
              'Mozilla/5.0 (iPad; CPU OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 appId/cn.edu.fzu.fdxypa appScheme/kysk-fdxy-app hengfeng/fdxyappzs appType/2 ruijie-facecamera',
          'Accept-Language': 'zh-CN,zh;q=0.9',
          'Connection': 'keep-alive',
        },
      ),
    );

    // 添加拦截器：每次请求自动带上 Token，响应时自动检查错误
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['token'] = token;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 原项目逻辑：如果 response.status === 500 (在 Dio 中通常是异常，但有时服务器会返回 200 并在 body 里写 code 500)
          // 这里处理业务上的 code 校验
          final data = response.data;
          if (data is Map && data['code'] == '500') {
            // Token 过期，需要在 UI 层处理跳转登录
            // 这里可以抛出一个特定的异常让 UI 捕获
            throw DioException(
              requestOptions: response.requestOptions,
              error: 'TokenExpired',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 500) {
            // 处理服务端 500 错误 (Token 过期等)
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_tokenKey);
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// 辅助方法：处理 POST 请求 (带重试机制)
  Future<dynamic> _post(
    String path, {
    Map<String, dynamic>? data,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await _dio.post(path, data: data);
        final result = response.data;

        // 有些接口返回的是 JSON 字符串，需要二次解析（原项目有这个逻辑）
        // 但 Dio 通常会自动解析 JSON。如果 API 返回的是 String，需要 jsonDecode。
        // 假设 Dio 已经解析好了 Map。

        if (result == null) throw Exception('请求结果为空');
        return result;
      } on DioException catch (e) {
        retryCount++;

        // 判断是否应该重试
        final shouldRetry = _shouldRetry(e, retryCount, maxRetries);

        if (!shouldRetry) {
          throw Exception(e.message ?? '网络请求失败');
        }

        // 指数退避：每次重试等待时间递增
        final waitTime = retryDelay * retryCount;
        await Future.delayed(waitTime);

        // 如果是最后一次重试仍然失败，抛出异常
        if (retryCount >= maxRetries) {
          throw Exception('请求超时或服务器无响应，已重试 $maxRetries 次');
        }
      }
    }

    throw Exception('网络请求失败');
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException e, int retryCount, int maxRetries) {
    if (retryCount >= maxRetries) return false;

    // 以下情况适合重试：
    // 1. 连接超时
    // 2. 接收超时
    // 3. 发送超时
    // 4. 服务器错误 (500, 502, 503, 504)
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return statusCode != null && (statusCode >= 500 && statusCode < 600);
      default:
        return false;
    }
  }

  // --- 业务接口实现 ---

  /// 1. 获取预约历史
  Future<List<Appointment>> fetchAppointments({
    required int currentPage,
    required int pageSize,
    String auditStatus = '',
  }) async {
    final data = await _post(
      '/spaceAppoint/app/queryMyAppoint',
      data: {
        'currentPage': currentPage.toString(),
        'pageSize': pageSize.toString(),
        'auditStatus': auditStatus,
      },
    );

    if (data['code'] == '0') {
      final List list = data['dataList'] ?? [];
      return list.map((e) => Appointment.fromJson(e)).toList();
    } else if (data['code'] == '403') {
      throw Exception('刷新过快，请稍等3分钟后重试');
    } else {
      throw Exception(data['msg'] ?? '获取预约历史失败');
    }
  }

  /// 2. 签到
  Future<void> signIn(String appointmentId) async {
    final data = await _post(
      '/station/app/signIn',
      data: {'id': appointmentId},
    );
    if (data['code'] != '0') {
      throw Exception('${data['code']} : ${data['msg']}');
    }
  }

  /// 3. 签退
  Future<void> signOut(String appointmentId) async {
    final data = await _post(
      '/station/app/signOut',
      data: {'id': appointmentId},
    );
    if (data['code'] != '0') {
      throw Exception('${data['code']} : ${data['msg']}');
    }
  }

  /// 4. 取消预约
  Future<void> cancelAppointment(String appointmentId) async {
    final data = await _post(
      '/spaceAppoint/app/revocationAppointApp',
      data: {'id': appointmentId},
    );
    if (data['code'] != '0') {
      throw Exception('取消预约失败: ${data['msg']}');
    }
  }

  /// 5. 查询座位状态 (用于地图显示)
  Future<List<SeatStatus>> querySeatStatus({
    required String date,
    required String beginTime,
    required String endTime,
    required String floor,
  }) async {
    final data = await _post(
      '/spaceAppoint/app/queryStationStatusByTime',
      data: {
        'beginTime': '$date $beginTime',
        'endTime': '$date $endTime',
        'floorLike': floor,
        'parentId': 'null',
        'region': '1',
      },
    );

    if (data['code'] == '0') {
      final List list = data['dataList'] ?? [];
      return list.map((e) => SeatStatus.fromJson(e)).toList();
    } else {
      throw Exception('查询座位状态失败: ${data['msg']}');
    }
  }

  /// 6. 预约座位
  Future<void> makeAppointment({
    required String spaceName,
    required String date,
    required String beginTime,
    required String endTime,
  }) async {
    final spaceId = SeatMapping.convertSeatNameToId(
      int.parse(spaceName).toString(),
    );

    final data = await _post(
      '/spaceAppoint/app/addSpaceAppoint',
      data: {
        'spaceId': spaceId,
        'beginTime': beginTime,
        'endTime': endTime,
        'date': date,
      },
    );

    final code = data['code'];
    final msg = data['msg'];

    if (code != '0' && msg != '成功') {
      // 照搬原项目的错误提示逻辑
      if (msg.contains('所选空间已被预约')) throw Exception('该座位已被预约，请选择其他座位');
      if (msg.contains('预约时间不合理')) throw Exception('预约时间超过4.5小时，请重新选择');
      if (msg.contains('系统异常')) throw Exception('结束时间小于开始时间，请检查时间设置');
      if (msg.contains('时间格式不正确')) throw Exception('时间必须是整点或半点，请重新选择');
      if (msg.contains('预约空间不存在')) throw Exception('座位不存在，请检查座位号');
      throw Exception(msg);
    }
  }

  /// 7. 查询座位时间段可用状态 (TimeCard)
  Future<SeatTimeStatus> querySpaceAppointTime({
    required String spaceId, // 注意这里入参通常是 spaceId (转换后的)
    required String date,
  }) async {
    final data = await _post(
      '/spaceAppoint/app/querySpaceAppointTime',
      data: {'spaceId': spaceId, 'date': date},
    );

    if (data['code'] == '0') {
      return SeatTimeStatus.fromJson(data);
    } else {
      throw Exception('查询座位时段失败: ${data['msg']}');
    }
  }
}
