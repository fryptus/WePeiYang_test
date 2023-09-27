import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:we_pei_yang_flutter/auth/view/info/tju_rebind_dialog.dart';
import 'package:we_pei_yang_flutter/commons/network/classes_backend_service.dart';
import 'package:we_pei_yang_flutter/commons/network/classes_service.dart';
import 'package:we_pei_yang_flutter/commons/network/wpy_dio.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/gpa/model/gpa_model.dart';
import 'package:we_pei_yang_flutter/gpa/network/gpa_service.dart';

class GPANotifier with ChangeNotifier {
  /// 每学期的gpa数据
  List<GPAStat> _gpaStats = [];

  List<GPAStat> get gpaStats => _gpaStats;

  /// 外部更新gpa总数据时调用
  set gpaStats(List<GPAStat> newList) {
    _gpaStats = newList;
    _sort();
    notifyListeners();
  }

  /// 所有学期的gpa总数居
  Total? total;

  /// 当前显示的学年
  int _index = 0;

  set index(int newIndex) {
    if (newIndex == _index) return;
    _index = newIndex;
    notifyListeners();
  }

  int get index => _index;

  /// 曲线上显示的种类, 0->weighted  1->gpa  2->credits
  int _type = 1;

  set type(int newType) {
    if (newType == _type) return;
    _type = newType;
    notifyListeners();
  }

  /// 通过[_type]获取种类名称
  String get typeName => ['加权', '绩点', '学分'][_type];

  /// 获取当前学年的weighted、gpa、credits
  /// 也可用来判断当前数据是否为空（如gpa_page.dart: [GPAStatsWidget]）
  List<double> get statsData {
    if (_gpaStats.length == 0) return [];
    var li = _gpaStats[_index];
    return [li.weighted, li.gpa, li.credits];
  }

  /// 获取曲线上的数据
  List<double> get curveData {
    var doubles = <double>[];
    if (_type == 0)
      for (var i in _gpaStats) doubles.add(i.weighted);
    else if (_type == 1)
      for (var i in _gpaStats) doubles.add(i.gpa);
    else if (_type == 2) for (var i in _gpaStats) doubles.add(i.credits);
    return doubles;
  }

  /// 获取所有学期名
  List<String> get terms => _gpaStats.map((e) => e.term).toList();

  /// 获取当前学年的course detail
  List<GPACourse> get courses {
    if (_gpaStats.length == 0) return [];
    return _gpaStats[_index].courses;
  }

  /// list的排列方式， 0->name 1->score 2->credit
  int _sortType = 0;

  String get sortType => ['name', 'score', 'credits'][_sortType];

  /// 更换排列方式
  void reSort() {
    _sortType = (_sortType + 1) % 3;
    _sort();
    notifyListeners();
  }

  /// 分别按 name、score、credit 排序
  void _sort() {
    switch (_sortType) {
      case 0:
        _gpaStats.forEach((element) {
          element.courses.sort((b, a) => a.name.compareTo(b.name));
        });
        break;
      case 1:
        _gpaStats.forEach((element) {
          element.courses.sort((b, a) => a.score.compareTo(b.score));
        });
        break;
      case 2:
        _gpaStats.forEach((element) {
          element.courses.sort((b, a) => a.credit.compareTo(b.credit));
        });
        break;
    }
  }

  /// notifier中也写一个hideGPA，就可以在从设置页面pop至主页时，令主页的GPAWidget进行rebuild
  set hideGPA(bool value) {
    CommonPreferences.hideGPA.value = value;
    notifyListeners();
  }

  bool get hideGPA => CommonPreferences.hideGPA.value;

  /// 使用后端爬虫（无需填写图形验证码）
  /// [CommonPreferences.useClassesBackend.value]决定了爬虫方式
  ///   --true: 使用后端的完整爬虫接口，直接获取办公网信息
  ///   --false: 仅使用后端ocr接口识别验证码
  /// 若失败则弹出TjuRebindDialog，用户手动填写图形验证码
  void refreshGPABackend(BuildContext context) async {
    ToastProvider.running("刷新数据中……");
    try {
      if (CommonPreferences.useClassesBackend.value) {
        var data = await ClassesBackendService.getClasses();
        if (data == null) throw WpyDioException(error: '云端获取课表失败');
        _gpaStats = data.item3.stats;
        total = data.item3.total;
        notifyListeners();
      } else {
        await ClassesService.getClasses(context);
      }
    } on DioException catch (_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) => TjuRebindDialog(),
      );
    }
  }

  /// 使用前端爬虫
  void refreshGPA({
    void Function()? onSuccess,
    void Function(DioException)? onFailure,
  }) {
    GPAService.getGPABean(onResult: (gpaBean) {
      _gpaStats = gpaBean.stats;
      total = gpaBean.total;
      notifyListeners();
      CommonPreferences.gpaData.value = json.encode(gpaBean);
      onSuccess?.call();
    }, onFailure: (e) {
      onFailure?.call(e);
    });
  }

  /// 从缓存中读课表的数据，进入主页之前调用
  void readPref() {
    if (CommonPreferences.gpaData.value == '') return;
    GPABean gpaBean =
        GPABean.fromJson(json.decode(CommonPreferences.gpaData.value));
    _gpaStats = gpaBean.stats;
    total = gpaBean.total;
    notifyListeners();
  }

  /// 办公网解绑时清除数据
  void clear() {
    _gpaStats = [];
    total = null;
    _index = 0;
    _type = 1;
    _sortType = 0;
    notifyListeners();
  }
}
