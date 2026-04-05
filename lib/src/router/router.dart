import 'package:flutter/material.dart';
import '../src.dart';

class RouteParams {
  final Map<String, dynamic> data;
  RouteParams(this.data);

  T? get<T>(String key) => data[key] as T?;
}

class AppRouter {
  // 全局导航键，在没有 context 的地方使用
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // 私有构造函数，单例模式
  AppRouter._internal();
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;

  // 路由表（命名路由与页面构造函数的映射）
  static final Map<String, Widget Function(BuildContext, RouteParams?)>
      _routes = {
    Routes.home: (context, params) => const HomePage(),
    Routes.musicPlayer: (context, params) => const MusicPlayerPage(),
    Routes.videoPlayer: (context, params) {
      print('=======builder: params.data=${params?.data}');
      final playlist = params?.get<List<MediaItem>>('playlist');
      return VideoPlayerPage(
        playlist: playlist ?? [],
        startIndex: params?.get<int>('startIndex') ?? 0,
      );
    },
    Routes.settings: (context, params) => const SettingsPage(),
  };

  // 路由守卫（拦截器），返回 null 表示放行，返回其他路由路径表示重定向
  static String? _routeGuard(RouteSettings settings) {
    return null;
  }

  // 全局路由观察者（用于埋点、日志等）
  static final NavigatorObserver _observer = _AppRouterObserver();

  // 获取 MaterialApp 所需的 onGenerateRoute 和 navigatorObservers
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final redirectPath = _routeGuard(settings);
    if (redirectPath != null) {
      // 执行重定向
      return _buildPageRoute(redirectPath, null, settings: settings);
    }

    // 解析参数
    RouteParams? params;
    if (settings.arguments is RouteParams) {
      params = settings.arguments as RouteParams;
    } else if (settings.arguments is Map<String, dynamic>) {
      params = RouteParams(settings.arguments as Map<String, dynamic>);
    }

    final builder = _routes[settings.name];
    if (builder != null) {
      return _buildPageRoute(settings.name!, params,
          settings: settings, builder: builder);
    }
    // 404 页面
    return _buildPageRoute('/404', null,
        settings: settings, builder: (context, _) => const NotFoundPage());
  }

  static PageRoute _buildPageRoute(
    String routeName,
    RouteParams? params, {
    required RouteSettings settings,
    Widget Function(BuildContext, RouteParams?)? builder,
  }) {
    final pageBuilder = builder ?? _routes[routeName];
    if (pageBuilder == null) {
      throw Exception('Route $routeName not found');
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => pageBuilder(context, params),
    );
  }

  static List<NavigatorObserver> get observers => [_observer];

  // ----- 导航方法（支持带参数）-----
  static Future<T?> push<T>(String routeName,
      {Map<String, dynamic>? arguments}) {
    // 获取当前路由名称
    final currentRouteName = AppRouter.currentRouteName;
    if (currentRouteName == routeName) {
      return Future.value(null); // 不跳转，直接返回
    }

    final params = arguments != null ? RouteParams(arguments) : null;
    print('push: $routeName, ${params?.data}');
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: params,
    );
  }

  static Future<T?> pushReplacement<T>(String routeName,
      {Map<String, dynamic>? arguments}) async {
    final params = arguments != null ? RouteParams(arguments) : null;
    final result = await navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: params,
    );
    return result as T?; // 安全转换，因为 result 可能是 T 或 null
  }

  static void pop<T>([T? result]) {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop(result);
    }
  }

  static Future<T?> pushAndRemoveUntil<T>(String routeName,
      {Map<String, dynamic>? arguments}) {
    final params = arguments != null ? RouteParams(arguments) : null;
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: params,
    );
  }

  // 返回上一页或指定页面
  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  // 获取当前路由名称
  static String? get currentRouteName {
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) return null;

    Route? currentRoute;
    // popUntil 会遍历路由栈，我们可以利用它来获取栈顶路由
    navigatorState.popUntil((route) {
      currentRoute = route;
      return true; // 立即停止遍历
    });
    return currentRoute?.settings.name;
  }
}

// 自定义路由观察者
class _AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    print('[Router] didPush: ${route.settings.name}');
    // 这里可以添加埋点统计
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    print('[Router] didPop: ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    print('[Router] didRemove: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    print('[Router] didReplace: ${newRoute?.settings.name}');
  }
}
