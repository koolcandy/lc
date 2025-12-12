// lib/data/enums/api_enums.dart

/// 对应后端的 ResultEnum
/// 参考: https://github.com/west2-online/fzuhelper-server/blob/main/pkg/errno/code.go
enum ResultCode {
  success('10000', '成功'),
  
  // Param errors (200xx)
  paramError('20001', '参数错误'),
  paramEmpty('20002', '参数为空'),
  paramMissingHeader('20003', '缺少请求头数据'),
  paramInvalid('20004', '参数无效'),
  paramMissing('20005', '参数缺失'),
  paramTooLong('20006', '参数过长'),
  paramTooShort('20007', '参数过短'),
  paramType('20008', '参数类型错误'),
  paramFormat('20009', '参数格式错误'),
  paramRange('20010', '参数范围错误'),
  paramValue('20011', '参数值错误'),
  paramFileNotExist('20012', '文件不存在'),
  paramFileReadError('20013', '文件读取错误'),

  // Auth errors (300xx)
  authError('30001', '鉴权错误'),
  authInvalid('30002', '鉴权无效'),
  authAccessExpired('30003', '访问令牌过期'),
  authRefreshExpired('30004', '刷新令牌过期'),
  authMissing('30005', '鉴权缺失'),

  // Biz errors (400xx)
  bizError('40001', '业务错误'),
  bizLogic('40002', '业务逻辑错误'),
  bizLimit('40003', '业务限制错误'),
  bizNotExist('40005', '业务不存在错误'),
  bizFileUploadError('40006', '文件上传错误'),
  bizJwchCookieException('40007', 'jwch cookie异常'),
  bizJwchEvaluationNotFound('40008', 'jwch 未进行评测'),

  // Internal errors (500xx)
  internalServiceError('50001', '未知服务错误'),
  internalDatabaseError('50002', '数据库错误'),
  internalRedisError('50003', 'Redis错误'),
  internalNetworkError('50004', '网络错误'),
  internalTimeoutError('50005', '超时错误'),
  internalIOError('50006', 'IO错误'),
  internalJSONError('50007', 'JSON错误'),
  internalXMLError('50008', 'XML错误'),
  internalURLEncodeError('50009', 'URL编码错误'),
  internalHTTPError('50010', 'HTTP错误'),
  internalHTTP2Error('50011', 'HTTP2错误'),
  internalGRPCError('50012', 'GRPC错误'),
  internalThriftError('50013', 'Thrift错误'),
  internalProtobufError('50014', 'Protobuf错误'),
  internalSQLError('50015', 'SQL错误'),
  internalNoSQLError('50016', 'NoSQL错误'),
  internalORMError('50017', 'ORM错误'),
  internalQueueError('50018', '队列错误'),
  internalETCDError('50019', 'ETCD错误'),
  internalTraceError('50020', 'Trace错误'),
  
  // Fallback for unknown codes
  unknown('-1', '未知错误');

  final String code;
  final String message;

  const ResultCode(this.code, this.message);

  /// 根据字符串 code 获取枚举值
  static ResultCode fromCode(String? code) {
    return ResultCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ResultCode.unknown,
    );
  }

  /// 判断是否是成功状态
  bool get isSuccess => code == '10000';
}

/// 成功状态码列表
const List<ResultCode> successCodeList = [
  ResultCode.success,
];

/// 对应前端定义的 RejectEnum
enum RejectCode {
  authFailed('10001', '鉴权异常'),
  reLoginFailed('10002', '重新登录异常'),
  bizFailed('10003', '业务异常'),
  internalFailed('10004', '内部异常'),
  timeout('10005', '请求超时'),
  networkError('10006', '网络异常'),
  nativeLoginFailed('10007', '本地登录异常'),
  evaluationNotFound('10008', '评测未找到'),
  
  unknown('-1', '未知异常');

  final String code;
  final String message;

  const RejectCode(this.code, this.message);
}