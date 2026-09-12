import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'auth_session.dart';

class ApiClient {
  final Dio dio;
  final AuthSession session;

  Future<bool> Function()?
      onRefreshRequested;

  Future<void> Function()?
      onSessionExpired;

  ApiClient({
    required String baseUrl,
    required this.session,
    Dio? dio,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,

                connectTimeout:
                    const Duration(
                  seconds: 10,
                ),

                receiveTimeout:
                    const Duration(
                  seconds: 15,
                ),

                sendTimeout:
                    const Duration(
                  seconds: 10,
                ),

                headers: {
                  'Content-Type':
                      'application/json',
                },
              ),
            ) {
    this.dio.options.baseUrl =
        baseUrl;

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          options,
          handler,
        ) {
          final token =
              session.accessToken;

          if (token != null &&
              token.isNotEmpty) {
            options.headers[
                    'Authorization'] =
                'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint(
              '[API] ${options.method} '
              '${options.uri}',
            );
          }

          handler.next(options);
        },

        onResponse: (
          response,
          handler,
        ) {
          if (kDebugMode) {
            debugPrint(
              '[API] '
              '${response.requestOptions.method} '
              '${response.requestOptions.uri} '
              '-> ${response.statusCode}',
            );
          }

          handler.next(response);
        },

        onError: (
          error,
          handler,
        ) async {
          if (kDebugMode) {
            debugPrint(
              '[API ERROR] '
              '${error.requestOptions.method} '
              '${error.requestOptions.uri} '
              '-> ${error.response?.statusCode}',
            );
          }

          final status =
              error.response?.statusCode;

          final path =
              error.requestOptions.path;

          final isAuthRequest =
              path.contains('/auth/');

          final alreadyRetried =
              error.requestOptions.extra[
                      'authRetried'] ==
                  true;

          if (status == 401 &&
              !isAuthRequest &&
              !alreadyRetried) {
            final refreshed =
                await onRefreshRequested
                        ?.call() ??
                    false;

            if (refreshed &&
                session.accessToken !=
                    null) {
              final options =
                  error.requestOptions;

              options.extra[
                      'authRetried'] =
                  true;

              options.headers[
                      'Authorization'] =
                  'Bearer '
                  '${session.accessToken}';

              try {
                final response =
                    await this
                        .dio
                        .fetch(options);

                handler.resolve(
                  response,
                );

                return;
              } on DioException catch (
                retryError
              ) {
                if (retryError
                        .response
                        ?.statusCode ==
                    401) {
                  await onSessionExpired
                      ?.call();
                }

                handler.next(
                  retryError,
                );

                return;
              }
            }

            await onSessionExpired
                ?.call();
          } else if (status == 401 &&
              !isAuthRequest &&
              alreadyRetried) {
            await onSessionExpired
                ?.call();
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>?
        queryParameters,
    CancelToken? cancelToken,
  }) async {
    const attempts = 3;

    for (
      var attempt = 1;
      attempt <= attempts;
      attempt++
    ) {
      try {
        return await dio.get(
          path,
          queryParameters:
              queryParameters,
          cancelToken: cancelToken,
        );
      } on DioException catch (error) {
        final exception =
            _mapException(error);

        if (exception
            is RequestCancelledException) {
          throw exception;
        }

        final retryable =
            exception
                    is NetworkException ||
                exception
                    is ServerException;

        if (!retryable ||
            attempt == attempts) {
          throw exception;
        }

        await Future.delayed(
          Duration(
            milliseconds:
                300 * attempt,
          ),
        );
      }
    }

    throw const NetworkException(
      'Не удалось выполнить запрос',
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>?
        queryParameters,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters:
            queryParameters,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
  }) async {
    try {
      return await dio.put(
        path,
        data: data,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>?
        queryParameters,
  }) async {
    try {
      return await dio.delete(
        path,
        queryParameters:
            queryParameters,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  ApiException _mapException(
    DioException error,
  ) {
    if (error.type ==
        DioExceptionType.cancel) {
      return const RequestCancelledException();
    }

    if (error.type ==
            DioExceptionType
                .connectionError ||
        error.type ==
            DioExceptionType
                .connectionTimeout ||
        error.type ==
            DioExceptionType
                .receiveTimeout ||
        error.type ==
            DioExceptionType
                .sendTimeout) {
      return const NetworkException(
        'Сервер недоступен. '
        'Проверьте подключение и настройки CORS.',
      );
    }

    final response =
        error.response;

    if (response == null) {
      return const NetworkException(
        'Нет ответа от сервера.',
      );
    }

    final status =
        response.statusCode ?? 0;

    final data =
        response.data;

    var message =
        'Ошибка сервера';

    if (data is Map &&
        data['message'] != null) {
      message =
          data['message'].toString();
    }

    switch (status) {
      case 400:
        return BadRequestException(
          message,
        );

      case 401:
        return UnauthorizedException(
          message,
        );

      case 403:
        return ForbiddenException(
          message,
        );

      case 404:
        return NotFoundException(
          message,
        );

      case 409:
        return ConflictException(
          message,
        );

      case 422:
        final errors =
            <String, String>{};

        if (data is Map &&
            data['errors'] is Map) {
          final source =
              data['errors'] as Map;

          for (
            final entry
            in source.entries
          ) {
            errors[
                    entry.key
                        .toString()] =
                entry.value
                    .toString();
          }
        }

        return ValidationException(
          message,
          errors,
        );

      default:
        if (status >= 500) {
          return ServerException(
            message,
          );
        }

        return ApiException(
          message,
        );
    }
  }
}